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
//                               idxram.v: indices RAM                            //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module idxram
 #( parameter                CDEP = 4       ,  // depth (k-entries, power of 2)
    parameter                PIPE = 1       )  // pipelined?
  ( input                    clk            ,  // clock
    input                    rst            ,  // global registers reset
    input                    wEnb           ,  // write enable
    input  [`log2(CDEP)+9:0] wAddr          ,  // write address
    input  [4            :0] vacFLoc        ,  // vacancy first location
    input  [4            :0] newPattOccFLoc ,  // first location of a new pattern occurrence
    output [4            :0] oldIdx         ,  // old pattern index
    output [4            :0] newIdx         ); // new pattern index
 
  wire [2            :0] wAddrLL = wAddr[2            :0];
  wire [1            :0] wAddrLH = wAddr[4            :3];
  wire [4            :0] wAddrL  = wAddr[4            :0];
  wire [`log2(CDEP)+4:0] wAddrH  = wAddr[`log2(CDEP)+9:5];

  wire [32*5-1:0] rIdx;
  genvar gi;
  generate
    for (gi=0 ; gi<4 ; gi=gi+1) begin: STG
      // instantiate M20K
      mwm20k #( .WWID  (5                     ),  // write width
                .RWID  (40                    ),  // read width
                .WDEP  (CDEP*1024/4           ),  // write lines depth
                .OREG  (0                     ),  // read output reg
                .INIT  (1                     ))  // initialize to zeros
      idxrami ( .clk   (clk                   ),  // clock         // input
                .rst   (rst                   ),  // global reset  // input
                .wEnb  ( wEnb && (gi==wAddrLH)),  // write enable  // input : choose block
                .wAddr ({wAddrH,wAddrLL}      ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData (vacFLoc               ),  // write data    // input  [WWID-1                   :0]
                .rAddr (wAddrH                ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData (rIdx[gi*40 +: 40]     )); // read data     // output [RWID-1                   :0]
    end
  endgenerate

///////////////////////////////////////////////////////////////////////////////

  // generate old pattern index

`ifdef SIM
  // HDL muxes
  assign oldIdx = rIdx[ wAddrL*5 +: 5];
`else
  // custom synthesis muxes 
  mux_oldIdx mux_oldIdx_inst(clk,rst,rIdx,wAddrL,oldIdx);
`endif

///////////////////////////////////////////////////////////////////////////////

  // generate new pattern index

`ifdef SIM
  // HDL muxes
  assign newIdx = rIdx[newPattOccFLoc*5 +: 5];
`else
  // custom synthesis muxes 
  mux_newIdx mux_newIdx_inst(clk,rst,rIdx,newPattOccFLoc,newIdx);
`endif

///////////////////////////////////////////////////////////////////////////////

endmodule
