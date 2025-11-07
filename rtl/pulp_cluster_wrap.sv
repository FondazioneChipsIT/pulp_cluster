// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Yvan Tortorella <yvan.tortorella@unibo.it>


package pulp_cluster_wrap_package;

  localparam pulp_cluster_package::pulp_cluster_cfg_t Cfg = '{
    CoreType: pulp_cluster_package::RI5CY,
    NumCores: 8,
    DmaNumPlugs: 4,
    DmaNumOutstandingBursts: 8,
    DmaBurstLength: 256,
    NumMstPeriphs: 1,
    NumSlvPeriphs: 12,
    ClusterAlias: 1,
    ClusterAliasBase: 'h0,
    NumSyncStages: 3,
    UseHci: 1,
    TcdmSize: 128*1024,
    TcdmNumBank: 16,
    HwpePresent: 1,
    HwpeCfg: '{NumHwpes: 3, HwpeList: {pulp_cluster_package::SOFTEX, pulp_cluster_package::NEUREKA, pulp_cluster_package::REDMULE}},
    HwpeNumPorts: 9,
    HMRPresent: 1,
    HMRDmrEnabled: 1,
    HMRTmrEnabled: 1,
    HMRDmrFIxed: 0,
    HMRTmrFIxed: 0,
    HMRInterleaveGrps: 1,
    HMREnableRapidRecovery: 1,
    HMRSeparateDataVoters:1,
    HMRSeparateAxiBus:0,
    HMRNumBusVoters:1,
    EnableECC: 1,
    ECCInterco: 1,
    iCacheNumBanks: 2,
    iCacheNumLines: 1,
    iCacheNumWays: 4,
    iCacheSharedSize: 4*1024,
    iCachePrivateSize: 512,
    iCachePrivateDataWidth: 32,
    EnableReducedTag: 1,
    L2Size: 1000*1024,
    DmBaseAddr: 'h60203000,
    BootRomBaseAddr: 'h1C000000 + 'h8080,
    BootAddr: 'h1C000000 + 'h8080,
    EnablePrivateFpu: 1,
    EnablePrivateFpDivSqrt: 0,
    EnableSharedFpu: 0,
    EnableSharedFpDivSqrt: 0,
    NumSharedFpu: 0,
    NumAxiIn: 4,
    NumAxiOut: 3,
    AxiIdInWidth: 4,
    AxiIdOutWidth: 6,
    AxiAddrWidth: 32,
    AxiDataInWidth: 64,
    AxiDataOutWidth: 64,
    AxiUserWidth: 10,
    AxiMaxInTrans: 64,
    AxiMaxOutTrans: 64,
    AxiCdcLogDepth: 3,
    AxiCdcSyncStages: 3,
    SyncStages: 3,
    ClusterBaseAddr: 'h10000000,
    ClusterPeriphOffs: 'h00200000,
    ClusterExternalOffs: 'h00400000,
    EnableRemapAddress: 0,
    SnitchICache: 0,
    default: '0
  };

  localparam int unsigned EventWidth = 8;

  // CDC AXI parameters (external to cluster)
  localparam int unsigned AwInWidth = axi_pkg::aw_width(Cfg.AxiAddrWidth,
                                                        Cfg.AxiIdInWidth,
                                                        Cfg.AxiUserWidth);
  localparam int unsigned WInWidth = axi_pkg::w_width(Cfg.AxiDataInWidth,
                                                      Cfg.AxiUserWidth);
  localparam int unsigned BInWidth = axi_pkg::b_width(Cfg.AxiIdInWidth,
                                                      Cfg.AxiUserWidth);
  localparam int unsigned ArInWidth = axi_pkg::ar_width(Cfg.AxiAddrWidth,
                                                        Cfg.AxiIdInWidth,
                                                        Cfg.AxiUserWidth);
  localparam int unsigned RInWidth = axi_pkg::r_width(Cfg.AxiDataInWidth,
                                                      Cfg.AxiIdInWidth,
                                                      Cfg.AxiUserWidth);
  localparam int unsigned AsyncInAwDatawidth = (2**Cfg.AxiCdcLogDepth)*AwInWidth;
  localparam int unsigned AsyncInWDatawidth  = (2**Cfg.AxiCdcLogDepth)*WInWidth;
  localparam int unsigned AsyncInBDataWidth  = (2**Cfg.AxiCdcLogDepth)*BInWidth;
  localparam int unsigned AsyncInArDatawidth = (2**Cfg.AxiCdcLogDepth)*ArInWidth;
  localparam int unsigned AsyncInRDataWidth  = (2**Cfg.AxiCdcLogDepth)*RInWidth;
  // CDC AXI parameters (cluster to external)
  localparam int unsigned AwOutWidth = axi_pkg::aw_width(Cfg.AxiAddrWidth,
                                                         Cfg.AxiIdOutWidth,
                                                         Cfg.AxiUserWidth);
  localparam int unsigned WOutWidth = axi_pkg::w_width(Cfg.AxiDataOutWidth,
                                                       Cfg.AxiUserWidth);
  localparam int unsigned BOutWidth = axi_pkg::b_width(Cfg.AxiIdOutWidth,
                                                       Cfg.AxiUserWidth);
  localparam int unsigned ArOutWidth = axi_pkg::ar_width(Cfg.AxiAddrWidth,
                                                         Cfg.AxiIdOutWidth,
                                                         Cfg.AxiUserWidth);
  localparam int unsigned ROutWidth = axi_pkg::r_width(Cfg.AxiDataOutWidth,
                                                       Cfg.AxiIdOutWidth,
                                                       Cfg.AxiUserWidth);
  localparam int unsigned AsyncOutAwDataWidth = (2**Cfg.AxiCdcLogDepth)*AwOutWidth;
  localparam int unsigned AsyncOutWDataWidth  = (2**Cfg.AxiCdcLogDepth)*WOutWidth;
  localparam int unsigned AsyncOutBDataWidth  = (2**Cfg.AxiCdcLogDepth)*BOutWidth;
  localparam int unsigned AsyncOutArDataWidth = (2**Cfg.AxiCdcLogDepth)*ArOutWidth;
  localparam int unsigned AsyncOutRDataWidth  = (2**Cfg.AxiCdcLogDepth)*ROutWidth;
  localparam int unsigned AsyncEventDataWidth = (2**Cfg.AxiCdcLogDepth)*EventWidth;
endpackage

module pulp_cluster_wrap (
  input  logic                                                      clk_i,
  input  logic                                                      rst_ni,
  input  logic                                                      ref_clk_i,
  input  logic                                                      pwr_on_rst_ni,
  input  logic                                                      pmu_mem_pwdn_i,
  input  logic [3:0]                                                base_addr_i,
  input  logic                                                      test_mode_i,
  input  logic                                                      en_sa_boot_i,
  input  logic [5:0]                                                cluster_id_i,
  input  logic                                                      fetch_en_i,
  output logic                                                      eoc_o,
  output logic                                                      busy_o,
  input  logic                                                      axi_isolate_i,
  output logic                                                      axi_isolated_o,
  input  logic                                                      dma_pe_evt_ack_i,
  output logic                                                      dma_pe_evt_valid_o,
  input  logic                                                      dma_pe_irq_ack_i,
  output logic                                                      dma_pe_irq_valid_o,
  input  logic                                                      pf_evt_ack_i,
  output logic                                                      pf_evt_valid_o,
  input  logic [pulp_cluster_wrap_package::Cfg.NumCores-1:0]        dbg_irq_valid_i,
  input  logic                                                      mbox_irq_i,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_cluster_events_wptr_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_cluster_events_rptr_o,
  input  logic [pulp_cluster_wrap_package::AsyncEventDataWidth-1:0] async_cluster_events_data_i,
  // AXI4 SLAVE
  //***************************************
  // WRITE ADDRESS CHANNEL
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_slave_aw_wptr_i,
  input  logic [pulp_cluster_wrap_package::AsyncInAwDatawidth-1:0] async_data_slave_aw_data_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_slave_aw_rptr_o,
  // READ ADDRESS CHANNEL
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_slave_ar_wptr_i,
  input  logic [pulp_cluster_wrap_package::AsyncInArDatawidth-1:0] async_data_slave_ar_data_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_slave_ar_rptr_o,
  // WRITE DATA CHANNEL
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_w_wptr_i,
  input  logic [pulp_cluster_wrap_package::AsyncInWDatawidth-1:0] async_data_slave_w_data_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_w_rptr_o,
  // READ DATA CHANNEL
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_r_wptr_o,
  output logic [pulp_cluster_wrap_package::AsyncInRDataWidth-1:0] async_data_slave_r_data_o,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_r_rptr_i,
  // WRITE RESPONSE CHANNEL
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_b_wptr_o,
  output logic [pulp_cluster_wrap_package::AsyncInBDataWidth-1:0] async_data_slave_b_data_o,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]  async_data_slave_b_rptr_i,
  // AXI4 MASTER
  //***************************************
  // WRITE ADDRESS CHANNEL
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_data_master_aw_wptr_o,
  output logic [pulp_cluster_wrap_package::AsyncOutAwDataWidth-1:0] async_data_master_aw_data_o,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_data_master_aw_rptr_i,
  // READ ADDRESS CHANNEL
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_data_master_ar_wptr_o,
  output logic [pulp_cluster_wrap_package::AsyncOutArDataWidth-1:0] async_data_master_ar_data_o,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]    async_data_master_ar_rptr_i,
  // WRITE DATA CHANNEL
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_w_wptr_o,
  output logic [pulp_cluster_wrap_package::AsyncOutWDataWidth-1:0] async_data_master_w_data_o,
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_w_rptr_i,
  // READ DATA CHANNEL
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_r_wptr_i,
  input  logic [pulp_cluster_wrap_package::AsyncOutRDataWidth-1:0] async_data_master_r_data_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_r_rptr_o,
  // WRITE RESPONSE CHANNEL
  input  logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_b_wptr_i,
  input  logic [pulp_cluster_wrap_package::AsyncOutBDataWidth-1:0] async_data_master_b_data_i,
  output logic [pulp_cluster_wrap_package::Cfg.AxiCdcLogDepth:0]   async_data_master_b_rptr_o
);

  pulp_cluster #( .Cfg(pulp_cluster_wrap_package::Cfg) ) pulp_cluster_i (
    .clk_i,
    .rst_ni,
    .pwr_on_rst_ni,
    .ref_clk_i,
    .axi_isolate_i ( '0 ),
    .axi_isolated_o,
    .pmu_mem_pwdn_i ( 1'b0 ),
    .base_addr_i,
    .dma_pe_evt_ack_i ( '1 ),
    .dma_pe_evt_valid_o,
    .dma_pe_irq_ack_i ( 1'b1 ),
    .dma_pe_irq_valid_o,
    .dbg_irq_valid_i ( '0 ),
    .mbox_irq_i ( '0  ),
    .pf_evt_ack_i ( 1'b1 ),
    .pf_evt_valid_o,
    .async_cluster_events_wptr_i ( '0 ),
    .async_cluster_events_rptr_o,
    .async_cluster_events_data_i ( '0 ),
    .en_sa_boot_i,
    .test_mode_i,
    .fetch_en_i,
    .eoc_o,
    .busy_o,
    .cluster_id_i,

    .async_data_master_aw_wptr_o,
    .async_data_master_aw_rptr_i,
    .async_data_master_aw_data_o,
    .async_data_master_ar_wptr_o,
    .async_data_master_ar_rptr_i,
    .async_data_master_ar_data_o,
    .async_data_master_w_data_o,
    .async_data_master_w_wptr_o,
    .async_data_master_w_rptr_i,
    .async_data_master_r_wptr_i,
    .async_data_master_r_rptr_o,
    .async_data_master_r_data_i,
    .async_data_master_b_wptr_i,
    .async_data_master_b_rptr_o,
    .async_data_master_b_data_i,

    .async_data_slave_aw_wptr_i,
    .async_data_slave_aw_rptr_o,
    .async_data_slave_aw_data_i,
    .async_data_slave_ar_wptr_i,
    .async_data_slave_ar_rptr_o,
    .async_data_slave_ar_data_i,
    .async_data_slave_w_data_i,
    .async_data_slave_w_wptr_i,
    .async_data_slave_w_rptr_o,
    .async_data_slave_r_wptr_o,
    .async_data_slave_r_rptr_i,
    .async_data_slave_r_data_o,
    .async_data_slave_b_wptr_o,
    .async_data_slave_b_rptr_i,
    .async_data_slave_b_data_o
  );
endmodule
