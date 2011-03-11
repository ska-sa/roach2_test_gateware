//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 3.6.1
//  \   \         Application: MIG
//  /   /         Filename: phy_rddata_sync.v
// /___/   /\     Date Last Modified: $Date: 2010/10/27 17:40:43 $
// \   \  /  \    Date Created: Aug 03 2009
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//   Synchronization of captured read data along with appropriately delayed
//   valid signal (both in clk_rsync domain) to MC/PHY rdlvl logic clock (clk)
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: phy_rddata_sync.v,v 1.1.2.1 2010/10/27 17:40:43 mishra Exp $
**$Date: 2010/10/27 17:40:43 $
**$Author: mishra $
**$Revision: 1.1.2.1 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/M/mig_v3_61/data/dlib/virtex6/ddr3_sdram/verilog/rtl/phy/Attic/phy_rddata_sync.v,v $
******************************************************************************/

`timescale 1ps/1ps


module phy_rddata_sync #
  (
   parameter TCQ             = 100,     // clk->out delay (sim only)
   parameter DQ_WIDTH        = 64,      // # of DQ (data)
   parameter DQS_WIDTH       = 8,       // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,       // # of DQ per DQS
   parameter nDQS_COL0       = 4,       // # DQS groups in I/O column #1
   parameter nDQS_COL1       = 4,       // # DQS groups in I/O column #2
   parameter nDQS_COL2       = 4,       // # DQS groups in I/O column #3
   parameter nDQS_COL3       = 4,       // # DQS groups in I/O column #4
   parameter DQS_LOC_COL0    = 32'h03020100,          // DQS grps in col #1
   parameter DQS_LOC_COL1    = 32'h07060504,          // DQS grps in col #2
   parameter DQS_LOC_COL2    = 0,                     // DQS grps in col #3
   parameter DQS_LOC_COL3    = 0                      // DQS grps in col #4
   )
  (
   input                        clk,
   input [3:0]                  clk_rsync,
   input [3:0]                  rst_rsync,
   // Captured data in resync clock domain
   input [DQ_WIDTH-1:0]         rd_data_rise0,
   input [DQ_WIDTH-1:0]         rd_data_fall0,
   input [DQ_WIDTH-1:0]         rd_data_rise1,
   input [DQ_WIDTH-1:0]         rd_data_fall1,
   input [DQS_WIDTH-1:0]        rd_dqs_rise0,
   input [DQS_WIDTH-1:0]        rd_dqs_fall0,
   input [DQS_WIDTH-1:0]        rd_dqs_rise1,
   input [DQS_WIDTH-1:0]        rd_dqs_fall1,
   // Synchronized data/valid back to MC/PHY rdlvl logic
   output reg [4*DQ_WIDTH-1:0]  dfi_rddata,
   output reg [4*DQS_WIDTH-1:0] dfi_rd_dqs
   );


  //***************************************************************************

  // Pipeline stage only required if timing not met otherwise
  always @(posedge clk) begin
    dfi_rddata <= #TCQ {rd_data_fall1,
                        rd_data_rise1,
                        rd_data_fall0,
                        rd_data_rise0};
    dfi_rd_dqs <= #TCQ {rd_dqs_fall1,
                        rd_dqs_rise1,
                        rd_dqs_fall0,
                        rd_dqs_rise0};
   end

endmodule
