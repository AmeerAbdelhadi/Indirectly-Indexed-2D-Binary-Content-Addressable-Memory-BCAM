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
//                               vacram.v: Vacancy RAM                            //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////


// 

`include "utils.vh"

module vacram
 #( parameter                CDEP = 4       ,  // depth (k-entries, power of 2)
    parameter                PIPE = 1       )  // pipelined?
  ( input                    clk            ,  // clock
    input                    rst            ,  // global registers reset
    input                    wEnb           ,  // write enable
    input  [`log2(CDEP)+9:0] wAddr          ,  // write address
    input                    oldPattV       ,  // is old (rewritten) pattern valid?              / input from setram
    input                    oldPattMultiOcc,
    input                    newPattMultiOcc,
    input  [4            :0] oldIdx         ,
    output [4            :0] vacFLoc        ); // vacancy first location

  wire [`log2(CDEP)+4:0] wAddrH  = wAddr[`log2(CDEP)+9:5];

  wire [31:0] rVac;
  wire [31:0] cVac;
  wire [31:0] wVac;

      mwm20k #( .WWID (32          ),  // write width
                .RWID (32          ),  // read width
                .WDEP (CDEP*1024/32),  // write lines depth
                .OREG (0           ),  // read output reg
                .INIT (1           ))  // initialize to zeros
      vacrami ( .clk  (clk         ),  // clock         // input
                .rst  (rst         ),  // global reset  // input
                .wEnb (wEnb        ),  // write enable  // input : choose block
                .wAddr(wAddrH      ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData(wVac        ),  // write data    // input  [WWID-1                   :0]
                .rAddr(wAddrH      ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData(rVac        )); // read data     // output [RWID-1                   :0]

///////////////////////////////////////////////////////////////////////////////

  // generate address of first vacancy
  wire NC;
`ifdef SIM
  pe_bhv #( .OHW(32) )  // behavioural priority encoder
`else
  pe_vac // generated automatically by ./pe script
`endif
  pe_vac_inst (
    .clk(clk    ), // clock for pipelined priority encoder
    .rst(rst    ), // registers reset for pipelined priority encoder
    .oht(cVac   ), // one-hot match input / in : [      CDEP -1:0]
    .bin(vacFLoc), // first match index   / out: [`log2(CDEP)-1:0]
    .vld(NC     )  // match indicator     / out
  );

///////////////////////////////////////////////////////////////////////////////

  // oldIdx one-hot decoder
  reg [31:0] oldIdxOH;
  always @(*) begin
    oldIdxOH         = {32{1'b0}};
    oldIdxOH[oldIdx] =     1'b1  ;
  end

///////////////////////////////////////////////////////////////////////////////
  
  // vacFLoc one-hot decoder
  reg [31:0] vacFLocOH;
  always @(*) begin
    vacFLocOH         = {32{1'b0}};
    vacFLocOH[vacFLoc] =    1'b1  ;
  end

///////////////////////////////////////////////////////////////////////////////

  // masking logic
  assign cVac =  (~rVac) | (  oldIdxOH   & {32{!oldPattMultiOcc && oldPattV}}) ; // current vacancy with old data place
  assign wVac = ~( cVac  & ((~vacFLocOH) | {32{ newPattMultiOcc            }})); // write-back vacancy status


///////////////////////////////////////////////////////////////////////////////

endmodule

