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
//          ii2dcam.v: indirectly-indexed 2D BCAM (II2DCAM) top hierarchy         //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

// include config file for synthesis mode
`ifndef SIM
`include "config.vh"
`endif

module ii2dcam
 #( parameter                CDEP = `CDEP , // CAM depth (k-entries, power of 2)
    parameter                PWID = `PWID , // pattern width (9-bits multiply)
    parameter                PIPE = `PIPE , // pipelined?
    parameter                REGI = `REGI , // register inputs?
    parameter                REGO = `REGO ) // register outputs?
  ( input                    clk          ,  // clock
    input                    rst          ,  // global reset
    input                    wEnb         ,  // write enable
    input  [`log2(CDEP)+9:0] wAddr        ,  // write address
    input  [PWID*9-1:0]      mPatt        ,  // match pattern
    input  [PWID*9-1:0]      wPatt        ,  // write pattern
    output                   match        ,  // match
    output [`log2(CDEP)+9:0] mAddr        ); // match indicators

  // register inputs
  reg                    wEnbR ;
  reg  [`log2(CDEP)+9:0] wAddrR;
  reg  [PWID*9-1:0]      mPattR;
  reg  [PWID*9-1:0]      wPattR;
  wire                   wEnbI ;
  wire [`log2(CDEP)+9:0] wAddrI;
  wire [PWID*9-1:0]      mPattI;
  wire [PWID*9-1:0]      wPattI;
  always @(posedge clk, posedge rst)
    if (rst) {wEnbR,wAddrR,mPattR,wPattR} <= {(`log2(CDEP)+18*PWID+11){1'b0}};
    else     {wEnbR,wAddrR,mPattR,wPattR} <= 
             {wEnb ,wAddr ,mPatt ,wPatt } ;

  assign     {wEnbI,wAddrI,mPattI,wPattI} = REGI  ?
             {wEnbR,wAddrR,mPattR,wPattR} : 
             {wEnb ,wAddr ,mPatt ,wPatt } ;

  // register outputs
  reg                    matchR;
  reg  [`log2(CDEP)+9:0] mAddrR;
  wire                   matchI;
  wire [`log2(CDEP)+9:0] mAddrI;
  always @(posedge clk, posedge rst)
    if (rst) {matchR,mAddrR} <= {(`log2(CDEP)+11){1'b0}};
    else     {matchR,mAddrR} <= 
             {matchI,mAddrI} ;

    assign   {match ,mAddr } = REGO ?
             {matchR,mAddrR} :
             {matchI,mAddrI} ;


  // instantiate slices of ii2dcam9b for each 9-bits of pattern
  wire [CDEP*1024-1:0] mIndc_i [PWID-1:0];
  genvar gi;
  generate
    for (gi=0 ; gi<PWID ; gi=gi+1) begin: STG
      // instantiate ii2dcam9b
      ii2dcam9b #( .CDEP (CDEP             ),   // depth (k-entries)
                   .PIPE (PIPE             ))   // pipelined?
      ii2dcam9bi ( .clk  (clk              ),   // clock // input
                   .rst  (rst              ),   // global reset // input
                   .wEnb (wEnbI            ),   // write enable // input
                   .wAddr(wAddrI           ),   // write address // input [`log2(DEP)+9:0]
                   .mPatt(mPattI[gi*9 +: 9]),   // match pattern // input [8 :0] 
                   .wPatt(wPattI[gi*9 +: 9]),   // write pattern // input [8 :0] 
                   .mIndc(mIndc_i[gi]      ));  // match indicators // output [DEP*1024-1:0]
    end
  endgenerate

  // cascading by AND'ing matches
  integer i;
  reg [CDEP*1024-1:0] mIndc; // match one-hot
  always @(*) begin
    mIndc = {(CDEP*1024){1'b1}};
    for (i=0; i<PWID; i=i+1)
      mIndc = mIndc & mIndc_i[i];
  end



  // binary match (priority encoded) with CDEPx1k width
`ifdef SIM
  pe_bhv #( .OHW(CDEP*1024) ) // behavioural priority encoder
`else
  pe_cam // generated automatically by ./pe script
`endif
  pe_cam_inst (
    .clk(clk   ), // clock for pipelined priority encoder
    .rst(rst   ), // registers reset for pipelined priority encoder
    .oht(mIndc ), // one-hot match input / in : [      CDEP -1:0]
    .bin(mAddrI), // first match index   / out: [`log2(CDEP)-1:0]
    .vld(matchI)  // match indicator     / out
  );

endmodule
