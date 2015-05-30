////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2014, University of British Columbia (UBC); All rights reserved. //
//                                                                                //
// Redistribution  and  use  in  source   and  binary  forms,   with  or  without //
// modification,  are permitted  provided that  the following conditions are met: //
//   * Redistributions   of  source   code  must  retain   the   above  copyright //
//     notice,  this   list   of   conditions   and   the  following  disclaimer. //
//   * Redistributions  in  binary  form  must  reproduce  the  above   copyright //
//     notice, this  list  of  conditions  and the  following  disclaimer in  the //
//     documentation and/or  other  materials  provided  with  the  distribution. //
//   * Neither the name of the University of British Columbia (UBC) nor the names //
//     of   its   contributors  may  be  used  to  endorse  or   promote products //
//     derived from  this  software without  specific  prior  written permission. //
//                                                                                //
// THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" //
// AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE //
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE //
// DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE //
// FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL //
// DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR //
// SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER //
// CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, //
// OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE //
// OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. //
////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////
//                              setram.v: Sets RAM                                //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////


// sets RAM

`include "utils.vh"

module setram
 #( parameter                CDEP = 4       ,  // CAM depth (k-entries, power of 2)
    parameter                PIPE = 1       )  // pipelined?
  ( input                    clk            ,  // clock
    input                    rst            ,  // global registers reset
    input                    wEnb           ,  // write enable
    input  [8            :0] wPatt          ,  // write pattern
    input  [`log2(CDEP)+9:0] wAddr          ,  // write address
    output [8            :0] oldPatt        ,  // old (rewritten) pattern
    output                   oldPattV       ,  // is old pattern valid?
    output                   oldPattMultiOcc,  // does old pattern has multi(other)-occurrences?
    output                   newPattMultiOcc,  // does new pattern has multi(other)-occurrences?
    output [4            :0] newPattOccFLoc ,  // first location of a new pattern occurrence
    output [31           :0] oldPattIndc    ,  // old pattern indicators
    output [31           :0] newPattIndc    ); // current new pattern indicators (w/  written pattern)

  wire [1            :0] wAddrLL = wAddr[1            :0];
  wire [2            :0] wAddrLH = wAddr[4            :2];
  wire [4            :0] wAddrL  = wAddr[4            :0];
  wire [`log2(CDEP)+4:0] wAddrH  = wAddr[`log2(CDEP)+9:5];

  // wAddrL one-hot decoder
  reg [31:0] wAddrLOH;
  always @(*) begin
    wAddrLOH         = {32{1'b0}};
    wAddrLOH[wAddrL] =     1'b1  ;
  end

  wire [31    :0] rPattV;
  wire [32*9-1:0] rPatt ;
  genvar gi;
  generate
    for (gi=0 ; gi<8 ; gi=gi+1) begin: STG
      // instantiate M20K
      mwm20k #( .WWID  (10                                    ),  // write width
                .RWID  (40                                    ),  // read width
                .WDEP  (CDEP*1024/8                           ),  // write lines depth
                .OREG  (0                                     ),  // read output reg
                .INIT  (1                                     ))  // initialize to zeros
      setrami ( .clk   (clk                                   ),  // clock         // input
                .rst   (rst                                   ),  // global reset  // input
                .wEnb  ( wEnb && (gi==wAddrLH)                ),  // write enable  // input : choose block
                .wAddr ({wAddrH,wAddrLL}                      ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData ({1'b1,wPatt}                          ),  // write data    // input  [WWID-1                   :0]
                .rAddr (wAddrH                                ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData ({rPattV[gi*4+3],rPatt[ gi*36+27 +: 9],
                         rPattV[gi*4+2],rPatt[ gi*36+18 +: 9],
                         rPattV[gi*4+1],rPatt[ gi*36+9  +: 9],
                         rPattV[gi*4  ],rPatt[ gi*36    +: 9]})); // read data     // output [RWID-1                   :0]

    end
  endgenerate

///////////////////////////////////////////////////////////////////////////////

 // extract old pattern and valid bit

`ifdef SIM
  // HDL muxes
  assign oldPatt  = rPatt[ wAddrL*9 +: 9];
  assign oldPattV = rPattV[wAddrL       ];
`else
  // custom synthesis muxes 
  mux_oldPatt  mux_oldPatt_inst (clk,rst,rPatt ,wAddrL,oldPatt );
  mux_oldPattV mux_oldPattV_inst(clk,rst,rPattV,wAddrL,oldPattV);
`endif

///////////////////////////////////////////////////////////////////////////////

  // generate old pattern indicators

  reg  [31:0] oldPattIndcI;
  reg  [31:0] oldPattIndcR;
  integer si;

  // masking for old pattarn indicators
  always @(*)
    for (si=0;si<32;si=si+1)
      oldPattIndcI[si] = (rPatt[si*9 +: 9] == oldPatt) & !(wAddrLOH[si]) & rPattV[si];

  // register for pipelining
  always @(posedge clk, posedge rst)
    if (rst) oldPattIndcR <= 32'b0       ;
    else     oldPattIndcR <= oldPattIndcI;

  // pipeline if required
  assign oldPattIndc = PIPE ? oldPattIndcR : oldPattIndcI;

///////////////////////////////////////////////////////////////////////////////

 // detect if old pattern has multi-occurrence in segment

`ifdef SIM
  // HDL reduction OR
  assign oldPattMultiOcc = |(oldPattIndc);
`else
  // custom synthesis reduction OR
  reduction_or_OPMO reduction_or_OPMO_inst(clk,rst,oldPattIndc,oldPattMultiOcc);
`endif

///////////////////////////////////////////////////////////////////////////////

  // generate new pattern indicators

  wire [31:0] newPattIndc_prv ;
  reg  [31:0] newPattIndc_prvI;
  reg  [31:0] newPattIndc_prvR;


  // previous new pattern indicators (w/o written pattern)
  always @(*)
    for (si=0;si<32;si=si+1)
      newPattIndc_prvI[si] = (rPatt[si*9 +: 9] == wPatt)  & rPattV[si];

  // register for pipelining
  always @(posedge clk, posedge rst)
    if (rst) newPattIndc_prvR <= 32'b0           ;
    else     newPattIndc_prvR <= newPattIndc_prvI;

  // pipeline if required
  assign newPattIndc_prv = PIPE ? newPattIndc_prvR : newPattIndc_prvI;

  // add currently written pattern into indicators
  assign newPattIndc = newPattIndc_prv | wAddrLOH;


  // binary match newPattMultiOcc with 32 width
`ifdef SIM
  pe_bhv #( .OHW(32) )  // behavioural priority encoder
`else
  pe_multiOcc // generated automatically by ./pe script
`endif
  pe_multiOcc_inst (
    .clk(clk            ), // clock for pipelined priority encoder
    .rst(rst            ), // registers reset for pipelined priority encoder
    .oht(newPattIndc_prv), // one-hot match input / in : [      CDEP -1:0]
    .bin(newPattOccFLoc ), // first match index   / out: [`log2(CDEP)-1:0]
    .vld(newPattMultiOcc    )  // match indicator     / out
  );

endmodule
