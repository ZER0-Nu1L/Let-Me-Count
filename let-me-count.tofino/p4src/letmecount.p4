/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "common/headers.p4"
#include "common/util.p4"

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<8> TYPE_LMC =  0x17;

/* Table Sizes */
const int IPV4_HOST_SIZE = 65536;

#ifdef USE_ALPM
const int IPV4_LPM_SIZE  = 400*1024;
#else
const int IPV4_LPM_SIZE  = 12288;
#endif

/* Users */

header lmc_t {
    bit<16> control_bit;
    bit<32> num;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    lmc_t        lmc;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */    
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    TofinoIngressParser() tofino_parser;

     state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_LMC: parse_lmc;
            default: accept;
        }
    }

    state parse_lmc {
        pkt.extract(hdr.lmc);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{

    bit<32> tmp1 = 0x00;
    bit<32> tmp2 = 0x00;
    bit<32> zero_index = 0x00;
    bit<32> z_temp = 0x00;

    action send_back() {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }

    table send_back_table {
        actions = {
            send_back;
        }
        const default_action = send_back;
        size = 1;
    }

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
#ifdef BYPASS_EGRESS
        ig_tm_md.bypass_egress = 1;
#endif
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    table ipv4_host {
        key = { 
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send; drop;
#ifdef ONE_STAGE
            @defaultonly NoAction;
#endif /* ONE_STAGE */
        }
        
#ifdef ONE_STAGE
        const default_action = NoAction();
#endif /* ONE_STAGE */

        size = IPV4_HOST_SIZE;
    }

#if defined(USE_ALPM)      
    @alpm(1)
    @alpm_partitions(2048)
#endif    
    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }
        
        default_action = send(64);
        size           = IPV4_LPM_SIZE;
    }

    Hash<bit<32>>(HashAlgorithm_t.RANDOM) hashAlg;
    bit<32> hash_output = 0;
    action hash_action() {
        hash_output = hashAlg.get<bit<32>>(hdr.ipv4.src_addr);
    }

    table hash_table {
        actions = {
            hash_action;
        }
        default_action = hash_action;
        size = 1;
    }

    action get_tmp() {
        tmp1 = hash_output;
        tmp2 = -hash_output;
    }

    table tmp_table {
        actions = {
            get_tmp;
        }
        default_action = get_tmp();
        size = 1;
    }

    action get_index() {
        zero_index = tmp1 & tmp2;
    }

    table index_table {
        actions = {
            get_index;
        }
        default_action = get_index();
        size = 1;
    }

    action set_lmc_num(bit<32> zero_num) {
        z_temp = zero_num;
    }

    table lmc_num_table {
        key = {
            zero_index: exact;
        }
        actions = {
            set_lmc_num;
        }
        size = 32;
    }

    Register<bit<32>, _>(32) max_zero_num;

    RegisterAction<bit<32>, _, bit<32>>(max_zero_num) get_zero_num = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            if (z_temp > value) {
                value = z_temp;
            }
            read_value = value;
        }
    };

    action updata_max_zero_num() {
        // hdr.lmc.num = get_zero_num.execute(0); // DEBUG: 
        z_temp = get_zero_num.execute(0);
    }

    table max_zero_num_table {
        actions = {
            updata_max_zero_num;
        }
        default_action = updata_max_zero_num();
        size = 1;
    }

    RegisterAction<bit<32>, _, bit<32>>(max_zero_num) reset_zero_num = {
        void apply(inout bit<32> value) {
            value = 0;
        }
    };

    action reset_max_zero_num() {
        reset_zero_num.execute(0);
    }

    table max_zero_num_reset_table {
        actions = {
            reset_max_zero_num;
        }
        default_action = reset_max_zero_num();
        size = 1;
    }

    action terminate() {
        hdr.lmc.num = z_temp;
        send(1);
    }

    table term_table {
        actions = {
            terminate;
        }
        default_action = terminate();
        size = 1;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            // if (!ipv4_host.apply().hit) {
            //     ipv4_lpm.apply();
            // }
            if (hdr.lmc.isValid()) {
                if (hdr.lmc.control_bit == 0) {
                    max_zero_num_reset_table.apply();
                } else {
                    // h = Hash(hdr.ipv4.src_addr)
                    hash_table.apply(); 
                    // z_temp <- trailingZeroBits(h)
                    tmp_table.apply();
                    index_table.apply();
                    lmc_num_table.apply();
                    // z_temp = max{z_temp, value_from_before}
                    max_zero_num_table.apply();
                }
            }
        }
        // hdr.lmc.num = z_temp;
        term_table.apply();
    }
}

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EmptyEgressParser(),
    EmptyEgress(),
    EmptyEgressDeparser()
) pipe;

Switch(pipe) main;