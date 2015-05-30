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
//          ii2dcam_tb.v: indirectly-indexed 2D BCAM (II2DCAM) Testbench          //
//                                                                                //
// Author: Ameer M. S. Abdelhadi ( ameer@ece.ubc.ca ; ameer.abdelhadi@gmail.com ) //
// SRAM-based Modular II-2D-BCAM ; The University of British Columbia , Sep. 2014 //
////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ps/1 ps

`include "utils.vh"

// toggle a clock CLK TOGn times each with PHASE clock phase length
`define CLKTOG(CLK,TOGn,PHASE) repeat (TOGn) #PHASE CLK=!CLK

module ii2dcam_tb;

  localparam PHASE = 10; // clock phase length

  // dump all internal signals and memory content into a status file; used for debugging
  task statdump;
    input [31:0] id;
    integer sfd; // status file descriptor
    integer i,j;
    reg [1:8*10] sfn; // status file name
    reg matchb_;
    reg [9:0] mAddr_;
  begin   
    // prepare status file
    $sformat(sfn,"stt%0d",id);
    $write("Writing status file: %0s ...\n",sfn); 
    sfd = $fopen(sfn,"w"); // open status file descriptor for write

    // controller
    $fwrite(sfd,"controller:\n=======\n");
    $fwrite(sfd,"Internal:\n");
    $fwrite(sfd,"  curStt          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.curStt         ,ii2dcami.STG[0].ii2dcam9bi.camctli.curStt         );
    $fwrite(sfd,"  nxtStt          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.nxtStt         ,ii2dcami.STG[0].ii2dcam9bi.camctli.nxtStt         );
    $fwrite(sfd,"Inputs:\n");
    $fwrite(sfd,"  wEnb            = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb           ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb           );
    $fwrite(sfd,"  oldPattV        = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.oldPattV       ,ii2dcami.STG[0].ii2dcam9bi.camctli.oldPattV       );
    $fwrite(sfd,"  oldPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.oldPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.camctli.oldPattMultiOcc);
    $fwrite(sfd,"  newPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.newPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.camctli.newPattMultiOcc);
    $fwrite(sfd,"Outputs:\n");
    $fwrite(sfd,"  wEnb_setram     = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_setram    ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_setram    );
    $fwrite(sfd,"  wEnb_idxram     = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_idxram    ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_idxram    );
    $fwrite(sfd,"  wEnb_vacram     = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_vacram    ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_vacram    );
    $fwrite(sfd,"  wEnb_indc       = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_indc      ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_indc      );
    $fwrite(sfd,"  wEnb_indx       = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_indx      ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_indx      );
    $fwrite(sfd,"  wEnb_iVld       = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_iVld      ,ii2dcami.STG[0].ii2dcam9bi.camctli.wEnb_iVld      );
    $fwrite(sfd,"  wIVld           = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.wIVld          ,ii2dcami.STG[0].ii2dcam9bi.camctli.wIVld          );
    $fwrite(sfd,"  oldNewbPattWr   = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.camctli.oldNewbPattWr  ,ii2dcami.STG[0].ii2dcam9bi.camctli.oldNewbPattWr  );

    // iitram
    // interface
    $fwrite(sfd,"\niitram:\n=======\n");
    $fwrite(sfd,"Inputs:\n");
    $fwrite(sfd,"  wEnb_iVld  = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_iVld ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_iVld);
    $fwrite(sfd,"  wEnb_indx  = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_indx ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_indx);
    $fwrite(sfd,"  wEnb_indc  = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_indc ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wEnb_indc);
    $fwrite(sfd,"  mPatt      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.mPatt     ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.mPatt     );
    $fwrite(sfd,"  wPatt      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wPatt     ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wPatt     );
    $fwrite(sfd,"  wAddr_indx = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wAddr_indx,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wAddr_indx);
    $fwrite(sfd,"  wAddr_indc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wAddr_indc,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wAddr_indc);
    $fwrite(sfd,"  wIndx      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIndx     ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIndx     );
    $fwrite(sfd,"  wIVld      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIVld     ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIVld     );
    $fwrite(sfd,"  wIndc      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIndc     ,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.wIndc     );
    // RAM
    $fwrite(sfd,"vld,idx RAM:\n");
    for (i=0;i<512;i=i+1) begin
      $fwrite(sfd,"%4d=%03h: ",i,i);
      for (j=0;j<32;j=j+1) begin
        case (j[4:3])
          0: $fwrite(sfd, "%b,%02d     ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.ivldram.altsyncm20k.mem_data[32*i+j],ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].indxram.altsyncm20k.mem_data[8*i+j[2:0]]);
          1: $fwrite(sfd, "%b,%02d     ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.ivldram.altsyncm20k.mem_data[32*i+j],ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].indxram.altsyncm20k.mem_data[8*i+j[2:0]]);
          2: $fwrite(sfd, "%b,%02d     ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.ivldram.altsyncm20k.mem_data[32*i+j],ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].indxram.altsyncm20k.mem_data[8*i+j[2:0]]);
          3: $fwrite(sfd, "%b,%02d     ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.ivldram.altsyncm20k.mem_data[32*i+j],ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].indxram.altsyncm20k.mem_data[8*i+j[2:0]]);
        endcase
      end
      $fwrite(sfd,"\n");
    end
      $fwrite(sfd,"vld,idx = "); for (i=0;i<32;i=i+1) $fwrite(sfd,"%b,%02d     ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.iVld[i],ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.indx[i[4:3]][i[2:0]*5 +: 5]); $fwrite(sfd,"\n");
    // MLAB
    $fwrite(sfd,"indc MLAB:\n");
    for (i=0;i<32;i=i+1) begin
      $fwrite(sfd,"%4d=%03h: ",i,i);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[0].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[1].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[2].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[3].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[4].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[5].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[6].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[0].STG[7].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[0].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[1].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[2].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[3].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[4].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[5].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[6].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[1].STG[7].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[0].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[1].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[2].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[3].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[4].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[5].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[6].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[2].STG[7].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[0].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[1].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[2].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[3].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[4].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[5].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[6].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.STG[3].STG[7].indcram.altsyncmlab.mem_data[i]);
      $fwrite(sfd,"\n");
    end
    $fwrite(sfd,"indc   =  "); for (i=0;i<32;i=i+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.indc[i*32 +: 32] ); $fwrite(sfd,"\n");
    $fwrite(sfd,"mIndc  =  "); for (i=0;i<32;i=i+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.mIndc[i*32 +: 32]); $fwrite(sfd,"\n");
    `PRIENC(`CDEP*1024,ii2dcami.STG[0].ii2dcam9bi.iitram9bi.STG[0].iitram9bx1ki.mIndc,{matchb_,mAddr_});
    $fwrite(sfd,"v,mAddr = %b,%h (%05d)\n",!matchb_,mAddr_dut,mAddr_);

    // setram
    // interface
    $fwrite(sfd,"\nsetram:\n=======\n");
    $fwrite(sfd,"Inputs:\n");
    $fwrite(sfd,"  wEnb            = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wEnb           ,ii2dcami.STG[0].ii2dcam9bi.setrami.wEnb           );
    $fwrite(sfd,"  wPatt           = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wPatt          ,ii2dcami.STG[0].ii2dcam9bi.setrami.wPatt          );
    $fwrite(sfd,"  wAddr           = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wAddr          ,ii2dcami.STG[0].ii2dcam9bi.setrami.wAddr          );
    $fwrite(sfd,"Outputs:\n");
    $fwrite(sfd,"  oldPatt        = %b,%b = %h,%h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattV       ,ii2dcami.STG[0].ii2dcam9bi.setrami.oldPatt  ,ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattV ,ii2dcami.STG[0].ii2dcam9bi.setrami.oldPatt     );
    $fwrite(sfd,"  oldPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattMultiOcc);
    $fwrite(sfd,"  newPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.newPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.setrami.newPattMultiOcc);
    $fwrite(sfd,"  newPattOccFLoc   = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.newPattOccFLoc ,ii2dcami.STG[0].ii2dcam9bi.setrami.newPattOccFLoc );
    $fwrite(sfd,"  oldPattIndc      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattIndc    ,ii2dcami.STG[0].ii2dcam9bi.setrami.oldPattIndc    );
    $fwrite(sfd,"  newPattIndc      = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.newPattIndc    ,ii2dcami.STG[0].ii2dcam9bi.setrami.newPattIndc    );
    $fwrite(sfd,"Internal:\n");
    $fwrite(sfd,"  wAddrLL         = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrLL        ,ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrLL        );
    $fwrite(sfd,"  wAddrLH         = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrLH        ,ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrLH        );
    $fwrite(sfd,"  wAddrL          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrL         ,ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrL         );
    $fwrite(sfd,"  wAddrH          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrH         ,ii2dcami.STG[0].ii2dcam9bi.setrami.wAddrH         );
    // RAM
    $fwrite(sfd,"Sets RAM:\n");
    for (i=0;i<32;i=i+1) begin
        $fwrite(sfd,"%4d: ",i);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[0].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[0].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[1].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[1].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[2].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[2].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[3].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[3].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[4].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[4].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[5].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[5].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[6].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[6].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        for (j=0;j<4;j=j+1) $fwrite(sfd,"%b,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.STG[7].setrami.altsyncm20k.mem_data[4*i+j][9],ii2dcami.STG[0].ii2dcam9bi.setrami.STG[7].setrami.altsyncm20k.mem_data[4*i+j][8:0]);
        $fwrite(sfd,"\n");
    end
    $fwrite(sfd,"rPatt=");
    for (i=0;i<32;i=i+1) $fwrite(sfd,"%h,%h ",ii2dcami.STG[0].ii2dcam9bi.setrami.rPattV[i],ii2dcami.STG[0].ii2dcam9bi.setrami.rPatt[i*9 +: 9]);
    $fwrite(sfd,"\n");

    // idxram
    // interface
    $fwrite(sfd,"\nidxram:\n=======\n");
    $fwrite(sfd,"Inputs:\n");
    $fwrite(sfd,"  wEnb            = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wEnb           ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wEnb           );
    $fwrite(sfd,"  wAddr           = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddr          ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddr          );
    $fwrite(sfd,"  vacFLoc         = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.vacFLoc        ,ii2dcami.STG[0].ii2dcam9bi.idxrami.vacFLoc        );
    $fwrite(sfd,"  newPattOccFLoc  = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.newPattOccFLoc ,ii2dcami.STG[0].ii2dcam9bi.idxrami.newPattOccFLoc );
    $fwrite(sfd,"Outputs:\n");
    $fwrite(sfd,"  oldIdx          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.oldIdx         ,ii2dcami.STG[0].ii2dcam9bi.idxrami.oldIdx         );
    $fwrite(sfd,"  newIdx          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.newIdx         ,ii2dcami.STG[0].ii2dcam9bi.idxrami.newIdx         );
    $fwrite(sfd,"Internal:\n");
    $fwrite(sfd,"  wAddrLL         = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrLL        ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrLL        );
    $fwrite(sfd,"  wAddrLH         = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrLH        ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrLH        );
    $fwrite(sfd,"  wAddrL          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrL         ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrL         );
    $fwrite(sfd,"  wAddrH          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrH         ,ii2dcami.STG[0].ii2dcam9bi.idxrami.wAddrH         );
    // RAM
    $fwrite(sfd,"idx RAM:\n");
    for (i=0;i<32;i=i+1) begin
        $fwrite(sfd,"%4d: ",i);
        for (j=0;j<8;j=j+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.idxrami.STG[0].idxrami.altsyncm20k.mem_data[8*i+j]);
        for (j=0;j<8;j=j+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.idxrami.STG[1].idxrami.altsyncm20k.mem_data[8*i+j]);
        for (j=0;j<8;j=j+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.idxrami.STG[2].idxrami.altsyncm20k.mem_data[8*i+j]);
        for (j=0;j<8;j=j+1) $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.idxrami.STG[3].idxrami.altsyncm20k.mem_data[8*i+j]);
        $fwrite(sfd,"\n");
    end
    $fwrite(sfd,"rIdx= "); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%h ",ii2dcami.STG[0].ii2dcam9bi.idxrami.rIdx[i*5 +: 5]); $fwrite(sfd,"\n");

    // vacram
    // interface
    $fwrite(sfd,"\nvacram:\n=======\n");
    $fwrite(sfd,"Inputs:\n");
    $fwrite(sfd,"wEnb            = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.wEnb           ,ii2dcami.STG[0].ii2dcam9bi.vacrami.wEnb           );
    $fwrite(sfd,"wAddr           = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.wAddr          ,ii2dcami.STG[0].ii2dcam9bi.vacrami.wAddr          );
    $fwrite(sfd,"oldPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.oldPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.vacrami.oldPattMultiOcc);
    $fwrite(sfd,"newPattMultiOcc = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.newPattMultiOcc,ii2dcami.STG[0].ii2dcam9bi.vacrami.newPattMultiOcc);
    $fwrite(sfd,"Internal:\n");
    $fwrite(sfd,"wAddrH          = %b = %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.wAddrH         ,ii2dcami.STG[0].ii2dcam9bi.vacrami.wAddrH         );
    // RAM
    $fwrite(sfd,"vac RAM:\n");
    for (i=0;i<32;i=i+1) begin
      $fwrite(sfd,"%6d: ",i);
      for (j=0;j<32;j=j+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.vacrami.altsyncm20k.mem_data[i][j]);
      $fwrite(sfd,"\n");
    end
    $fwrite(sfd,"rVac=   "); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.rVac[i]     ); $fwrite(sfd,"\n");
    $fwrite(sfd,"cVac=   "); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.cVac[i]     ); $fwrite(sfd,"\n");
    $fwrite(sfd,"vacFLoc="); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.vacFLocOH[i]); $fwrite(sfd,"= %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.vacFLoc);
    $fwrite(sfd,"wVac=   "); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.wVac[i]     ); $fwrite(sfd,"\n");
    $fwrite(sfd,"oldIdx= "); for (i=0;i<32;i=i+1)  $fwrite(sfd,"%b ",ii2dcami.STG[0].ii2dcam9bi.vacrami.oldIdxOH[i] ); $fwrite(sfd,"= %h\n",ii2dcami.STG[0].ii2dcam9bi.vacrami.oldIdx);
    $fclose(sfd);
  end
  endtask


  reg pass = 1'b1; // simulation passed
  integer cycc=0; // cycle count

  integer rep_fd, ferr; // report file

  // interface signals
  reg                     clk   =  1'b0 ;
  reg                     rst   =  1'b1 ;
  reg                     wEnb  =  1'b0 ;
  reg  [`log2(`CDEP)+9:0] wAddr = {(`log2(`CDEP)+10){1'b0}} ;
  reg  [9*`PWID-1     :0] mPatt = {(9*`PWID        ){1'b0}} ;
  reg  [9*`PWID-1     :0] wPatt = {(9*`PWID        ){1'b0}} ;
  wire                    match_dut, match_bhv;
  wire [`log2(`CDEP)+9:0] mAddr_dut, mAddr_bhv;

  initial begin


    rep_fd = $fopen("sim.res","r"); // try to open report file for read
    $ferror(rep_fd,ferr);       // detect error
    $fclose(rep_fd);
    rep_fd = $fopen("sim.res","a+"); // open report file for append
    if (ferr) begin     // if file is new (can't open for read); write header
      $fwrite(rep_fd,"Pattern  BCAM     Sim.     Sim.   \n");
      $fwrite(rep_fd,"Width    Depth-k  Cycles#  Result \n");
      $fwrite(rep_fd,"==================================\n");
    end
    // print header
    $write("\nSimulating BCAM with the following parameters:\n");
    $write("CAM depth            : %0d\n",`CDEP);
    $write("Pattern width        : %0d\n",`PWID );
    $write("Simulation Cycles    : %0d\n\n",`CYCC);

    #(10*PHASE) rst = 1'b0; // exit reset
    #PHASE   
    //statdump(0);
    while (pass && (cycc<=`CYCC)) begin
      wEnb  = 1'b1                   ; // enable writing
      `GETRAND(wPatt,9*`PWID)        ; // generate random write pattern
      `GETRAND(wAddr,`log2(`CDEP)+10); // generate random write address
      `CLKTOG(clk,2,PHASE)           ; // 1 cycles
      wEnb  = 1'b0                   ; // disable writing
      `CLKTOG(clk,6,PHASE)           ; // 3 cycles to complete writing
      `GETRAND(mPatt,9*`PWID)        ; // generate random match pattern
      `CLKTOG(clk,4,PHASE)           ; // 2 cycles to complete matching
      pass = ((!match_dut) && (!match_bhv)) || (match_dut && match_bhv && (mAddr_dut == mAddr_bhv)); // compute equivalence
      if (`VERBOSE || !pass)
        $write("%07d: Write: wPatt=%h; Waddr=%h --- Match: mPatt=%h; {match,mAddr}={ref:%b,%h}-{dut:%b,%h} - %s\n", // verbosed
                cycc,wPatt,wAddr,mPatt,match_bhv,mAddr_bhv,match_dut,mAddr_dut, pass ? "PASS" : "FAIL");
      else if (cycc%100==0) $write("%07d: PASS\n",cycc); // report PASS/FAIL every 100 write/match operations
      cycc=cycc+1;
    end
    //statdump(1);
    $fwrite(rep_fd,"%-7d  %-7d  %-7d  %s\n",`PWID,`CDEP,`CYCC,pass ? "PASS" : "FAIL");
    $write("\n*** Simulation %s after %0d cycles.\n\n",pass ? "PASSED" : "FAILED", cycc-1);
    $fclose(rep_fd);
    $finish;
  end

  // DUT: ii2dcam instantiation
  ii2dcam #( .CDEP (`CDEP    ),  // depth (k-entries, power of 2)
             .PWID (`PWID    ),  // pattern width (9-bits multiply)
             .PIPE (0        ),  // pipelined?
             .REGI (0        ),  // register inputs
             .REGO (0        ))  // register outputs
  ii2dcami ( .clk  (clk      ),  // clock               / input
             .rst  (rst      ),  // global reset        / input
             .wEnb (wEnb     ),  // write enable        / input
             .wAddr(wAddr    ),  // write address       / input  [log2(CDEP)+9:0]
             .mPatt(mPatt    ),  // match pattern       / input  [PWID*9-1    :0]
             .wPatt(wPatt    ),  // write pattern       / input  [PWID*9-1    :0]
             .match(match_dut),  // match (valid mAddr) / output
             .mAddr(mAddr_dut)); // match address       / output [log2(CDEP)+9:0]

  // Behavioral BCAM
  bcam_bhv  #( .CDEP (`CDEP*1024),  // CAM depth
               .PWID (`PWID*9   ),  // CAM/pattern width
               .INOM (1         ))  // binary          / Initial CAM with no match
  bcam_bhv_i ( .clk  (clk       ),  // clock           / input
               .rst  (rst       ),  // global reset    / input
               .wEnb (wEnb      ),  // write enable    / input
               .wAddr(wAddr     ),  // write address   / input [`log2(CDEP)-1:0]
               .wPatt(wPatt     ),  // write pattern   / input
               .mPatt(mPatt     ),  // patern to match / input [      PWID -1:0]
               .match(match_bhv ),  // match indicator / output
               .mAddr(mAddr_bhv )); // matched address / output [`log2(CDEP)-1:0]

endmodule
