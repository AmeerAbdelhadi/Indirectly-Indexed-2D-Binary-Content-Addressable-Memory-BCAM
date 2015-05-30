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
//  ii2dcam9b.v: An indirectly-indexed 2D BCAM (II2DCAM) stage of 9-bits pattern  //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////


`include "utils.vh"

module ii2dcam9b
 #( parameter                CDEP = 4 ,   // depth (k-entries, power of 2)
    parameter                PIPE = 1 )   // pipelined?
  ( input                    clk      ,   // clock
    input                    rst      ,   // global registers reset
    input                    wEnb     ,   // write enable
    input  [`log2(CDEP)+9:0] wAddr    ,   // write address
    input  [8 :0]            mPatt    ,   // match pattern
    input  [8 :0]            wPatt    ,   // write pattern
    output [CDEP*1024-1:0]   mIndc    );  // match indicators

  wire        oldPattMultiOcc ;
  wire        newPattMultiOcc ;
  wire [4 :0] newPattOccFLoc  ;
  wire [8 :0] oldPatt         ;
  wire [31:0] wIndc           ;
  wire [4 :0] oldIdx          ;
  wire [4 :0] newIdx          ;
  wire [4 :0] wIndx           ;
  wire [4 :0] vacFLoc         ;
  wire        oldNewbPattWr   ;

  // pipelining //

  wire        oldPattMultiOccI;
  wire        newPattMultiOccI;
  wire [4 :0] newPattOccFLocI ;
  wire [8 :0] oldPattI        ;
  wire [31:0] wIndcI          ;
  wire [4 :0] oldIdxI         ;
  wire [4 :0] newIdxI         ;
  wire [4 :0] wIndxI          ;
  wire [4 :0] vacFLocI        ;
  wire        oldNewbPattWrI  ;

  reg        oldPattMultiOccR;
  reg        newPattMultiOccR;
  reg [4 :0] newPattOccFLocR ;
  reg [8 :0] oldPattR        ;
  reg [31:0] wIndcR          ;
  reg [4 :0] oldIdxR         ;
  reg [4 :0] newIdxR         ;
  reg [4 :0] wIndxR          ;
  reg [4 :0] vacFLocR        ;
  reg        oldNewbPattWrR  ;

  always @(posedge clk, posedge rst)
    if (rst) {oldPattMultiOccR,newPattMultiOccR,newPattOccFLocR,oldPattR,wIndcR,oldIdxR,newIdxR,wIndxR,vacFLocR,oldNewbPattWrR} <= {54{1'b0}};
    else     {oldPattMultiOccR,newPattMultiOccR,newPattOccFLocR,oldPattR,wIndcR,oldIdxR,newIdxR,wIndxR,vacFLocR,oldNewbPattWrR} <= 
             {oldPattMultiOccI,newPattMultiOccI,newPattOccFLocI,oldPattI,wIndcI,oldIdxI,newIdxI,wIndxI,vacFLocI,oldNewbPattWrI};

  assign     {oldPattMultiOcc ,newPattMultiOcc ,newPattOccFLoc ,oldPatt ,wIndc ,oldIdx ,newIdx ,wIndx ,vacFLoc ,oldNewbPattWr } = PIPE ?
             {oldPattMultiOccR,newPattMultiOccR,newPattOccFLocR,oldPattR,wIndcR,oldIdxR,newIdxR,wIndxR,vacFLocR,oldNewbPattWrR} :
             {oldPattMultiOccI,newPattMultiOccI,newPattOccFLocI,oldPattI,wIndcI,oldIdxI,newIdxI,wIndxI,vacFLocI,oldNewbPattWrI} ;

///////////////////////////////////////////////////////////////////////////////

  // control signals
  wire oldPattV, wEnb_iVld ,wEnb_indx, wEnb_indc, wEnb_setram, wEnb_idxram, wEnb_vacram, wIVld;

  camctl
  camctli ( .clk            (clk                ),  // clock                                          / input 
            .rst            (rst                ),  // global registers reset                         / input
            .wEnb           (wEnb               ),  // CAM write enable                               / input
            .oldPattV       (oldPattV           ),  // is old (rewritten) pattern valid?              / input from setram
            .oldPattMultiOcc(oldPattMultiOcc    ),  // does old pattern has multi(other)-occurrences? / input from setram
            .newPattMultiOcc(newPattMultiOcc    ),  // does new pattern has multi(other)-occurrences? / input from setram
            .oldEqNewPatt   (oldPatt==wPatt     ),
            .wEnb_setram    (wEnb_setram        ),  // write enable to sets RAM                       / output to setram
            .wEnb_idxram    (wEnb_idxram        ),  // write enable to indices RAM                    / output to idxram
            .wEnb_vacram    (wEnb_vacram        ),  // write enable to vacancy RAM                    / output to vacram
            .wEnb_indc      (wEnb_indc          ),  // write enable / full indicators MLABs           / output to iitram9b
            .wEnb_indx      (wEnb_indx          ),  // write enable / indicator index RAM             / output to iitram9b
            .wEnb_iVld      (wEnb_iVld          ),  // write enable / indicator valid RAM             / output to iitram9b
            .wIVld          (wIVld              ),  // write indicator validity                       / output to iitram9b
            .oldNewbPattWr  (oldNewbPattWrI     )); // old pattern / new pattern (inverted) write     / output

///////////////////////////////////////////////////////////////////////////////

  wire [31:0] oldPattIndc;
  wire [31:0] newPattIndc;

  // write indicators mux; either old or new pattern indicators are written into iitram
  assign wIndcI = oldNewbPattWr ? oldPattIndc : newPattIndc;

  // write indicators mux; 
  wire [4:0] oldIdx_ = oldPattMultiOcc ? oldIdx : {5'b0} ;
  wire [4:0] newIdx_ = newPattMultiOcc ? newIdx : vacFLoc;
  assign wIndxI = oldNewbPattWr ? oldIdx_ : newIdx_;

///////////////////////////////////////////////////////////////////////////////

  iitram9b #( .DEP       (CDEP                  ),  // depth (k-entries, power of 2)
              .PIPE      (PIPE                  ))  // pipelined?
  iitram9bi ( .clk       (clk                   ),  // clock                                      / input
              .rst       (rst                   ),  // global registers reset                     / input
              .wEnb_iVld (wEnb_iVld             ),  // write enable / indicator valid RAM         / input
              .wEnb_indx (wEnb_indx             ),  // write enable / indicator index RAM         / input
              .wEnb_indc (wEnb_indc             ),  // write enable / full indicators MLABs       / input
              .mPatt     (mPatt                 ),  // match pattern                              / input  [8   :0]
              .wPatt     (oldNewbPattWr ? oldPatt : wPatt),  // write pattern                              / input  [8   :0]
              .wAddr_indx(wAddr[`log2(CDEP)+9:5]),  // write address / index                      / input  [4   :0]
              .wAddr_indc(wIndx                 ),  // write address / indicator (in index range) / input  [4   :0]
              .wIndx     (wIndx                 ),  // write index                                / input  [4   :0]
              .wIVld     (wIVld                 ),  // write indicator validity                   / input 
              .wIndc     (wIndc                 ),  // write indicator (full)                     / input  [31  :0]
              .mIndc     (mIndc                 )); // match indicators                           / output [1023:0]

///////////////////////////////////////////////////////////////////////////////

  setram #( .CDEP           (CDEP               ),  // CAM depth (k-entries)
            .PIPE           (PIPE               ))  // pipelined?
  setrami ( .clk            (clk                ),  // clock                                                / input
            .rst            (rst                ),  // global registers reset                               / input
            .wEnb           (wEnb_setram        ),  // write enable                                         / input
            .wPatt          (wPatt              ),  // write pattern                                        / input  [8           :0]
            .wAddr          (wAddr              ),  // write address                                        / input  [log2(CDEP)+9:0]
            .oldPatt        (oldPattI           ),  // old (rewritten) pattern                              / output [8           :0]
            .oldPattV       (oldPattV           ),  // is old (rewritten) pattern valid?                    / output
            .oldPattMultiOcc(oldPattMultiOccI   ),  // does old pattern has multi(other)-occurrences?       / output
            .newPattMultiOcc(newPattMultiOccI   ),  // does new pattern has multi(other)-occurrences?       / output
            .newPattOccFLoc (newPattOccFLocI    ),  // first location of a new pattern occurrence           / output [4          :0]
            .oldPattIndc    (oldPattIndc        ),  // old pattern indicators                               / output [31         :0]
            .newPattIndc    (newPattIndc        )); // current new pattern indicators (w/  written pattern) / output [31         :0]

///////////////////////////////////////////////////////////////////////////////

  idxram #( .CDEP           (CDEP               ),  // depth (k-entries)
            .PIPE           (PIPE               ))  // pipelined?
  idxrami ( .clk            (clk                ),  // clock                                      // input 
            .rst            (rst                ),  // global reset                               // input 
            .wEnb           (wEnb_idxram        ),  // write enable                               // input 
            .wAddr          (wAddr              ),  // write address                              // input  [`log2(CDEP)+9:0]
            .vacFLoc        (newIdx_            ),  // vacancy first location                     // input  [4            :0]
            .newPattOccFLoc (newPattOccFLoc     ),  // first location of a new pattern occurrence // input  [4            :0]
            .oldIdx         (oldIdxI            ),  // old pattern index                          // output [4            :0]
            .newIdx         (newIdxI            )); // new pattern index                          // output [4            :0]

///////////////////////////////////////////////////////////////////////////////

  vacram #( .CDEP           (CDEP               ),  // depth (k-entries) // input
            .PIPE           (PIPE               ))  // pipelined?
  vacrami ( .clk            (clk                ),  // clock // input
            .rst            (rst                ),  // global reset // input
            .wEnb           (wEnb_vacram        ),  // write enable // input
            .wAddr          (wAddr              ),  // write address // [`log2(CDEP)+9:0] input
            .oldPattV       (oldPattV           ),  // is old (rewritten) pattern valid?              / input from setram
            .oldPattMultiOcc(oldPattMultiOcc    ),  // input
            .newPattMultiOcc(newPattMultiOcc    ),  // input
            .oldIdx         (oldIdx             ),  // [4:0] input
            .vacFLoc        (vacFLocI           )); // [4:0] output

///////////////////////////////////////////////////////////////////////////////

endmodule
