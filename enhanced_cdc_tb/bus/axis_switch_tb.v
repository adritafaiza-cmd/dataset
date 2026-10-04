`timescale 1ns/1ps
module axis_switch_tb;
  integer errors,sent0,sent1,got0,got1,age,i,j;
  reg clk,rst,s_valid,s_last;
  reg [7:0] s_data;
  reg s_dest;
  wire [1:0] s_ready,m_valid,m_last;
  wire [15:0] m_data;
  reg [1:0] m_ready;
  reg [1:0] prev_stall,prev_last;
  reg [15:0] prev_data;
  reg [7:0] exp0[0:31],exp1[0:31];
  always #5 clk=~clk;
  axis_switch #(.S_COUNT(2),.M_COUNT(2),.DATA_WIDTH(8),.KEEP_ENABLE(0),
    .ID_ENABLE(0),.USER_ENABLE(0),.M_DEST_WIDTH(1),.S_DEST_WIDTH(1),
    .S_REG_TYPE(2),.M_REG_TYPE(2)) dut(
    .clk(clk),.rst(rst),.s_axis_tdata({8'h00,s_data}),.s_axis_tkeep(2'b11),
    .s_axis_tvalid({1'b0,s_valid}),.s_axis_tready(s_ready),
    .s_axis_tlast({1'b0,s_last}),.s_axis_tid(16'b0),
    .s_axis_tdest({1'b0,s_dest}),.s_axis_tuser(2'b0),
    .m_axis_tdata(m_data),.m_axis_tkeep(),.m_axis_tvalid(m_valid),
    .m_axis_tready(m_ready),.m_axis_tlast(m_last),.m_axis_tid(),
    .m_axis_tdest(),.m_axis_tuser());
  always @(posedge clk) begin
    if(rst)begin prev_stall<=0;age<=0;end
    else begin
      if(m_valid[0]&&m_ready[0])begin
        if(got0>=sent0)begin $display("PROTOCOL VIOLATION [AXIS_OUTPUT_WITHOUT_INPUT]: port 0 output without input");errors=errors+1;end
        else if(m_data[7:0]!==exp0[got0])begin $display("PROTOCOL VIOLATION [AXIS_ROUTING_DATA]: port 0 data mismatch");errors=errors+1;end
        got0=got0+1;
      end
      if(m_valid[1]&&m_ready[1])begin
        if(got1>=sent1)begin $display("PROTOCOL VIOLATION [AXIS_OUTPUT_WITHOUT_INPUT]: port 1 output without input");errors=errors+1;end
        else if(m_data[15:8]!==exp1[got1])begin $display("PROTOCOL VIOLATION [AXIS_ROUTING_DATA]: port 1 data mismatch");errors=errors+1;end
        got1=got1+1;
      end
      if(prev_stall[0]&&(!m_valid[0]||m_data[7:0]!==prev_data[7:0]||m_last[0]!==prev_last[0]))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_STABILITY]: port 0 payload changed while stalled");errors=errors+1;end
      if(prev_stall[1]&&(!m_valid[1]||m_data[15:8]!==prev_data[15:8]||m_last[1]!==prev_last[1]))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_STABILITY]: port 1 payload changed while stalled");errors=errors+1;end
      if((m_valid[0]&&^m_data[7:0]===1'bx)||(m_valid[1]&&^m_data[15:8]===1'bx))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_KNOWN]: X in valid output");errors=errors+1;end
      if((sent0+sent1)>(got0+got1)&&(m_ready!=0))begin age<=age+1;if(age>80)begin $display("PROTOCOL VIOLATION [AXIS_FORWARD_PROGRESS]: bounded latency exceeded");errors=errors+1;age<=0;end end else age<=0;
      prev_stall<=m_valid&~m_ready;prev_data<=m_data;prev_last<=m_last;
    end
  end
  task send_packet;
    input [7:0] d;input dest;
    begin
      if(dest)begin exp1[sent1]=d;sent1=sent1+1;end
      else begin exp0[sent0]=d;sent0=sent0+1;end
      @(negedge clk);s_data=d;s_dest=dest;s_last=1;s_valid=1;while(!s_ready[0])@(negedge clk);
      @(negedge clk);s_valid=0;s_last=0;end
  endtask
  initial begin
    errors=0;sent0=0;sent1=0;got0=0;got1=0;age=0;clk=0;rst=1;s_valid=0;s_last=0;s_data=0;s_dest=0;m_ready=0;prev_stall=0;
    repeat(4)@(posedge clk);rst=0;
    fork
      begin for(i=0;i<24;i=i+1)send_packet(8'h40+i,i[0]);end
      begin for(j=0;j<100;j=j+1)begin @(negedge clk);m_ready[0]=(j%5)!=0;m_ready[1]=(j%7)>1;end m_ready=2'b11;end
    join
    while(got0<sent0||got1<sent1)@(posedge clk);
    m_ready=0;@(negedge clk);s_data=8'hee;s_dest=1;s_last=1;s_valid=1;
    repeat(2)@(posedge clk);rst=1;s_valid=0;s_last=0;
    repeat(3)@(posedge clk);rst=0;sent0=0;sent1=0;got0=0;got1=0;age=0;m_ready=2'b11;
    send_packet(8'h5a,1);while(got1<1)@(posedge clk);
    if(sent0!=got0||sent1!=got1)begin $display("PROTOCOL VIOLATION [AXIS_TRANSACTION_CONSERVATION]: per-port sent and received counts differ");errors=errors+1;end
    if(errors==0)$display("AXIS SWITCH ENHANCED: ALL TESTS PASSED");else $display("AXIS SWITCH ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #70000;$display("AXIS SWITCH ENHANCED: TIMEOUT");$finish;end
endmodule
