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
    bit<16> num;
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
    action miss() {
        ig_dprsr_md.drop_ctl = 0x1;
    }

    table miss_table {
        actions = {
            miss;
        }
        const default_action = miss;
        size = 1;
    }

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

    Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash1;
    Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash2;
    Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash3;

    bit<32> h_1 = 0;
    bit<32> h_2 = 0;
    bit<32> h_3 = 0;

    bit<32> tmp1_1 = 0x00;
    bit<32> tmp2_1 = 0x00;
    bit<32> tmp1_2 = 0x00;
    bit<32> tmp2_2 = 0x00;
    bit<32> tmp1_3 = 0x00;
    bit<32> tmp2_3 = 0x00;

    bit<32> zero_index_1 = 0x00;
    bit<32> zero_index_2 = 0x00;
    bit<32> zero_index_3 = 0x00;
    
    Register<bit<16>, _>(1, 0) z_1;
    Register<bit<16>, _>(1, 0) z_2;
    Register<bit<16>, _>(1, 0) z_3;

    bit<16> z_temp_1 = 0x00;
    bit<16> z_temp_2 = 0x00;
    bit<16> z_temp_3 = 0x00;
    bit<16> dif_13 = 0x00;
    bit<16> dif_12 = 0x00;
    bit<16> dif_23 = 0x00;

    
    /*************** Process 1 ***************/
    action hash_action_1() {
        h_1 = hash1.get<bit<32>>(hdr.ipv4.src_addr);
    }

    // hash the ipv4 addr
    table hash_table_1 {
        actions = {
            hash_action_1;
        }
        const default_action = hash_action_1;
        size = 1;
    }

    action get_tmp_1() {
        tmp1_1 = h_1;
        tmp2_1 = -h_1;
    }

    table tmp_table_1 {
        actions = {
            get_tmp_1;
        }
        default_action = get_tmp_1;
        size = 1;
    }

    action get_index_1() {
        zero_index_1 = tmp1_1 & tmp2_1;
    }

    table index_table_1 {
        actions = {
            get_index_1;
        }
        default_action = get_index_1;
        size = 1;
    }

    action set_lmc_num_1(bit<32> zero_num) {
        z_temp_1 = (bit<16>)zero_num;
    }

    table lmc_num_table_1 {
        key = {
            zero_index_1: exact;
        }
        actions = {
            set_lmc_num_1;
        }
        size = 32;
    }

    action terminate_1() {
        hdr.lmc.num = z_temp_1;
        ig_tm_md.ucast_egress_port = 1;
    }

    table term_table_1 {
        actions = {
            terminate_1;
        }
        const default_action = terminate_1;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_1) get_zero_num_1 = {
        void apply(inout bit<16> value, out bit<16> read_value) {
            if (z_temp_1 > value) {
                value = z_temp_1;
            }
            read_value = value;
        }
    };

    action updata_max_zero_num_1() {
        z_temp_1 = get_zero_num_1.execute(0);
    }

    table max_zero_num_table_1 {
        actions = {
            updata_max_zero_num_1;
        }
        default_action = updata_max_zero_num_1;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_1) reset_zero_num_1 = {
        void apply(inout bit<16> value) {
            value = 0;
        }
    };

    action reset_max_zero_num_1() {
        reset_zero_num_1.execute(0);
    }

    table max_zero_num_reset_table_1 {
        actions = {
            reset_max_zero_num_1;
        }
        default_action = reset_max_zero_num_1;
        size = 1;
    }

    /*************** Process 2 ***************/
    action hash_action_2() {
        h_2 = hash2.get<bit<32>>(hdr.ipv4.src_addr);
    }

    // hash the ipv4 addr
    table hash_table_2 {
        actions = {
            hash_action_2;
        }
        const default_action = hash_action_2;
        size = 1;
    }

    action get_tmp_2() {
        tmp1_2 = h_2;
        tmp2_2 = -h_2;
    }

    table tmp_table_2 {
        actions = {
            get_tmp_2;
        }
        default_action = get_tmp_2;
        size = 1;
    }

    action get_index_2() {
        zero_index_2 = tmp1_2 & tmp2_2;
    }

    table index_table_2 {
        actions = {
            get_index_2;
        }
        default_action = get_index_2;
        size = 1;
    }

    action set_lmc_num_2(bit<32> zero_num) {
        z_temp_2 = (bit<16>)zero_num;
    }

    table lmc_num_table_2 {
        key = {
            zero_index_2: exact;
        }
        actions = {
            set_lmc_num_2;
        }
        size = 32;
    }

    action terminate_2() {
        hdr.lmc.num = z_temp_2;
        ig_tm_md.ucast_egress_port = 1;
    }

    table term_table_2 {
        actions = {
            terminate_2;
        }
        const default_action = terminate_2;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_2) get_zero_num_2 = {
        void apply(inout bit<16> value, out bit<16> read_value) {
            if (z_temp_2 > value) {
                value = z_temp_2;
            }
            read_value = value;
        }
    };

    action updata_max_zero_num_2() {
        z_temp_2 = get_zero_num_2.execute(0);
    }

    table max_zero_num_table_2 {
        actions = {
            updata_max_zero_num_2;
        }
        default_action = updata_max_zero_num_2;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_2) reset_zero_num_2 = {
        void apply(inout bit<16> value) {
            value = 0;
        }
    };

    action reset_max_zero_num_2() {
        reset_zero_num_2.execute(0);
    }

    table max_zero_num_reset_table_2 {
        actions = {
            reset_max_zero_num_2;
        }
        default_action = reset_max_zero_num_2;
        size = 1;
    }

    /*************** Process 3 ***************/
    action hash_action_3() {
        h_3 = hash3.get<bit<32>>(hdr.ipv4.src_addr);
    }

    // hash the ipv4 addr
    table hash_table_3 {
        actions = {
            hash_action_3;
        }
        const default_action = hash_action_3;
        size = 1;
    }

    action get_tmp_3() {
        tmp1_3 = h_3;
        tmp2_3 = -h_3;
    }

    table tmp_table_3 {
        actions = {
            get_tmp_3;
        }
        default_action = get_tmp_3;
        size = 1;
    }

    action get_index_3() {
        zero_index_3 = tmp1_3 & tmp2_3;
    }

    table index_table_3 {
        actions = {
            get_index_3;
        }
        default_action = get_index_3;
        size = 1;
    }

    action set_lmc_num_3(bit<32> zero_num) {
        z_temp_3 = (bit<16>)zero_num;
    }

    table lmc_num_table_3 {
        key = {
            zero_index_3: exact;
        }
        actions = {
            set_lmc_num_3;
        }
        size = 32;
    }

    action terminate_3() {
        hdr.lmc.num = z_temp_3;
        ig_tm_md.ucast_egress_port = 1;
    }

    table term_table_3 {
        actions = {
            terminate_3;
        }
        const default_action = terminate_3;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_3) get_zero_num_3 = {
        void apply(inout bit<16> value, out bit<16> read_value) {
            if (z_temp_3 > value) {
                value = z_temp_3;
            }
            read_value = value;
        }
    };

    action updata_max_zero_num_3() {
        z_temp_3 = get_zero_num_3.execute(0);
    }

    table max_zero_num_table_3 {
        actions = {
            updata_max_zero_num_3;
        }
        default_action = updata_max_zero_num_3;
        size = 1;
    }

    RegisterAction<bit<16>, _, bit<16>>(z_3) reset_zero_num_3 = {
        void apply(inout bit<16> value) {
            value = 0;
        }
    };

    action reset_max_zero_num_3() {
        reset_zero_num_3.execute(0);
    }

    table max_zero_num_reset_table_3  {
        actions = {
            reset_max_zero_num_3;
        }
        default_action = reset_max_zero_num_3;
        size = 1;
    }

    action calculate_diff() {
        dif_13 = z_temp_1 - z_temp_3;
        dif_12 = z_temp_1 - z_temp_2;
        dif_23 = z_temp_2 - z_temp_3;
    }

    table diff_table {
        actions = {
            calculate_diff;
        }
        default_action = calculate_diff;
        size = 1;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            // drop all non-control packets
            // if (!hdr.lmc.isValid()) {
            //     miss_table.apply();
            // }
            // if (!ipv4_host.apply().hit) {
            //     ipv4_lpm.apply();
            // }
            if (hdr.lmc.isValid() && hdr.lmc.control_bit == 0) {
                max_zero_num_reset_table_1.apply();
                max_zero_num_reset_table_2.apply();
                max_zero_num_reset_table_3.apply();
            } else {
                // h = Hash(hdr.ipv4.src_addr)
                hash_table_1.apply();
                // z_temp <- trailingZeroBits(h)
                tmp_table_1.apply();
                index_table_1.apply();
                lmc_num_table_1.apply();
                // z_temp = max{z_temp, value_from_before}
                max_zero_num_table_1.apply();

                hash_table_2.apply();
                tmp_table_2.apply();
                index_table_2.apply();
                lmc_num_table_2.apply();
                max_zero_num_table_2.apply();
                
                hash_table_3.apply();
                tmp_table_3.apply();
                index_table_3.apply();
                lmc_num_table_3.apply();
                max_zero_num_table_3.apply();
            }
        }
        if (hdr.lmc.isValid() && hdr.lmc.control_bit == 1) {
                diff_table.apply();
                if (dif_12 > 0)
                    if (dif_23 > 0)
                        term_table_2.apply();
                    else
                        if (dif_13 > 0)
                            term_table_3.apply();
                        else
                            term_table_1.apply();
                else
                    if (dif_23 < 0)
                        term_table_2.apply();
                    else if (dif_13 < 0)
                        term_table_3.apply();
                    else
                        term_table_1.apply();
        }
        // No need for egress processing, skip it and use empty controls for egress.
        ig_tm_md.bypass_egress = 1w1;
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