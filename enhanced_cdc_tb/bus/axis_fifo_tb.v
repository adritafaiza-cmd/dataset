`timescale 1ns/1ps
module axis_fifo_tb;
  integer errors,sent,received,age,i,j;
  reg clk,rst,s_valid,s_last,m_ready;
  reg [7:0] s_data;
  wire s_ready,m_valid,m_last;
  wire [7:0] m_data;
  reg prev_stall,prev_last;
  reg [7:0] prev_data,expected[0:127];
  always #5 clk=~clk;
  axis_fifo #(.DEPTH(16),.DATA_WIDTH(8),.KEEP_ENABLE(0),.LAST_ENABLE(1),
    .ID_ENABLE(0),.DEST_ENABLE(0),.USER_ENABLE(0)) dut(
    .clk(clk),.rst(rst),.s_axis_tdata(s_data),.s_axis_tkeep(1'b1),
    .s_axis_tvalid(s_valid),.s_axis_tready(s_ready),.s_axis_tlast(s_last),
    .s_axis_tid(8'b0),.s_axis_tdest(8'b0),.s_axis_tuser(1'b0),
    .m_axis_tdata(m_data),.m_axis_tkeep(),.m_axis_tvalid(m_valid),
    .m_axis_tready(m_ready),.m_axis_tlast(m_last),.m_axis_tid(),
    .m_axis_tdest(),.m_axis_tuser(),.pause_req(1'b0),.pause_ack(),
    .status_depth(),.status_depth_commit(),.status_overflow(),
    .status_bad_frame(),.status_good_frame());
  always @(posedge clk) begin
    if(rst)begin prev_stall<=0;age<=0;end
    else begin
      if(s_valid&&s_ready)begin expected[sent]=s_data;sent=sent+1;end
      if(m_valid&&m_ready)begin
        if(received>=sent)begin $display("PROTOCOL VIOLATION [AXIS_OUTPUT_WITHOUT_INPUT]: output without input");errors=errors+1;end
        else if(m_data!==expected[received])begin $display("PROTOCOL VIOLATION [AXIS_DATA_ORDER]: output data or ordering mismatch");errors=errors+1;end
        received=received+1;age<=0;
      end
      if(prev_stall&&(!m_valid||m_data!==prev_data||m_last!==prev_last))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_STABILITY]: payload changed while stalled");errors=errors+1;end
      if(m_valid&&((^m_data===1'bx)||(^m_last===1'bx)))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_KNOWN]: X in valid output");errors=errors+1;end
      if(sent>received&&m_ready)begin age<=age+1;if(age>80)begin $display("PROTOCOL VIOLATION [AXIS_FORWARD_PROGRESS]: bounded latency exceeded");errors=errors+1;age<=0;end end
      prev_stall<=m_valid&&!m_ready;prev_data<=m_data;prev_last<=m_last;
    end
  end
  task send_byte;
    input [7:0] d;input last;
    begin @(negedge clk);s_data=d;s_last=last;s_valid=1;while(!s_ready)@(negedge clk);
      @(negedge clk);s_valid=0;s_last=0;end
  endtask
  initial begin
    errors=0;sent=0;received=0;age=0;clk=0;rst=1;s_valid=0;s_last=0;s_data=0;m_ready=0;prev_stall=0;
    repeat(4)@(posedge clk);rst=0;
    fork
      begin for(i=0;i<40;i=i+1)send_byte(i[7:0],(i%10)==9);end
      begin for(j=0;j<140;j=j+1)begin @(negedge clk);m_ready=(j%7)>1;end m_ready=1;end
    join
    while(received<sent)@(posedge clk);
    m_ready=0;send_byte(8'hee,1);repeat(2)@(posedge clk);rst=1;s_valid=0;
    repeat(3)@(posedge clk);rst=0;sent=0;received=0;age=0;m_ready=1;
    send_byte(8'h5a,1);while(received<1)@(posedge clk);
    if(sent!=received)begin $display("PROTOCOL VIOLATION [AXIS_TRANSACTION_CONSERVATION]: sent=%0d received=%0d",sent,received);errors=errors+1;end
    if(errors==0)$display("AXIS FIFO ENHANCED: ALL TESTS PASSED");else $display("AXIS FIFO ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #60000;$display("AXIS FIFO ENHANCED: TIMEOUT");$finish;end
endmodule
