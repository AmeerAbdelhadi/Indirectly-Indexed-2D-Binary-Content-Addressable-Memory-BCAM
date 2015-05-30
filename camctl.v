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
//                           camctl.v: BCAM Controller                            //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

// Controller /  Mealy FSM
module camctl
  ( input       clk            ,  // clock                                          / input 
    input       rst            ,  // global registers reset                         / input
    input       wEnb           ,  // CAM write enable                               / input
    input       oldPattV       ,  // is old (rewritten) pattern valid?              / input from setram
    input       oldPattMultiOcc,  // does old pattern has multi(other)-occurrences? / input from setram
    input       newPattMultiOcc,  // does new pattern has multi(other)-occurrences? / input from setram
    input oldEqNewPatt,
    output reg  wEnb_setram    ,  // write enable to sets RAM                       / output to setram
    output reg  wEnb_idxram    ,  // write enable to indices RAM                    / output to idxram
    output reg  wEnb_vacram    ,  // write enable to vacancy RAM                    / output to vacram
    output reg  wEnb_indc      ,  // write enable / full indicators MLABs           / output to iitram9b
    output reg  wEnb_indx      ,  // write enable / indicator index RAM             / output to iitram9b
    output reg  wEnb_iVld      ,  // write enable / indicator valid RAM             / output to iitram9b
    output reg  wIVld          ,  // write indicator validity                       / output to iitram9b
    output reg  oldNewbPattWr  ); // old pattern / new pattern (inverted) write     / output

  // state declaration
  reg [1:0] curStt, nxtStt  ;
  localparam S0 = 2'b00;
  localparam S1 = 2'b01;
  localparam S2 = 2'b10;

  // synchronous process
  always @(posedge clk, posedge rst)
    if (rst) curStt <= S0    ;
    else     curStt <= nxtStt;

  // combinatorial process
  always @(*) begin
    {wEnb_setram,wEnb_idxram,wEnb_vacram,wEnb_indc,wEnb_indx,wEnb_iVld,wIVld,oldNewbPattWr} = 8'h00;
    case (curStt)
      S0: nxtStt = wEnb?S1:S0; // idle; read RAM and generate status
      S1: begin // delete old pattern
            nxtStt        = S2                          ;
            wEnb_indc     = !(oldEqNewPatt && oldPattV) && oldPattV &&  oldPattMultiOcc;
            wEnb_iVld     = !(oldEqNewPatt && oldPattV) && oldPattV && !oldPattMultiOcc;
            oldNewbPattWr = oldPattV                    ;
          end
      S2: begin // write new pattarn
            nxtStt        = S0                                                ;
            wEnb_setram   = !(oldEqNewPatt && oldPattV) && 1'b1                                              ;
//          wEnb_idxram   = !newPattMultiOcc                                  ;
            wEnb_idxram   = !(oldEqNewPatt && oldPattV) && 1'b1                                  ;
            wEnb_vacram   = !(oldEqNewPatt && oldPattV) && (oldPattV && !oldPattMultiOcc) || !newPattMultiOcc;
            wEnb_indc     = !(oldEqNewPatt && oldPattV) && 1'b1                                              ;
            wEnb_indx     = !(oldEqNewPatt && oldPattV) && !newPattMultiOcc                                  ;
            wEnb_iVld     = !(oldEqNewPatt && oldPattV) && !newPattMultiOcc                                  ;
            wIVld         = 1'b1                                              ;
            oldNewbPattWr = 1'b0                                              ;
          end
    endcase
  end

endmodule

