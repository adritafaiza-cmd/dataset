`timescale 1ns/1ps
module axis_adapter_tb;
  integer errors,in_beats,out_words,expected_words,age,i,j;
  reg clk,rst,s_valid,s_last,m_ready;
  reg [7:0] s_data;
  wire s_ready,m_valid,m_last;
  wire [31:0] m_data;
  wire [3:0] m_keep;
  reg prev_stall,prev_last;
  reg [31:0] prev_data,expected_data[0:31];
  reg [3:0] prev_keep,expected_keep[0:31];
  always #5 clk=~clk;
  axis_adapter #(.S_DATA_WIDTH(8),.S_KEEP_ENABLE(0),.M_DATA_WIDTH(32),
    .M_KEEP_ENABLE(1),.ID_ENABLE(0),.DEST_ENABLE(0),.USER_ENABLE(0)) dut(
    .clk(clk),.rst(rst),.s_axis_tdata(s_data),.s_axis_tkeep(1'b1),
    .s_axis_tvalid(s_valid),.s_axis_tready(s_ready),.s_axis_tlast(s_last),
    .s_axis_tid(8'b0),.s_axis_tdest(8'b0),.s_axis_tuser(1'b0),
    .m_axis_tdata(m_data),.m_axis_tkeep(m_keep),.m_axis_tvalid(m_valid),
    .m_axis_tready(m_ready),.m_axis_tlast(m_last),.m_axis_tid(),
    .m_axis_tdest(),.m_axis_tuser());
  always @(posedge clk) begin
    if(rst)begin prev_stall<=0;age<=0;end
    else begin
      if(s_valid&&s_ready)in_beats=in_beats+1;
      if(m_valid&&m_ready)begin
        if(out_words>=expected_words)begin $display("PROTOCOL VIOLATION [AXIS_OUTPUT_WITHOUT_INPUT]: output without input packet");errors=errors+1;end
        else begin
          if(m_keep!==expected_keep[out_words]||!m_last||
             (m_keep[0]&&m_data[7:0]!==expected_data[out_words][7:0])||
             (m_keep[1]&&m_data[15:8]!==expected_data[out_words][15:8])||
             (m_keep[2]&&m_data[23:16]!==expected_data[out_words][23:16])||
             (m_keep[3]&&m_data[31:24]!==expected_data[out_words][31:24]))begin
            $display("PROTOCOL VIOLATION [AXIS_WIDTH_ADAPTATION]: word=%0d data=%h keep=%h",out_words,m_data,m_keep);errors=errors+1;
          end
        end
        out_words=out_words+1;age<=0;
      end
      if(prev_stall&&(!m_valid||m_data!==prev_data||m_keep!==prev_keep||m_last!==prev_last))begin
        $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_STABILITY]: payload changed while stalled");errors=errors+1;
      end
      if(m_valid&&((^m_data===1'bx)||(^m_keep===1'bx)||(^m_last===1'bx)))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_KNOWN]: X in valid output");errors=errors+1;end
      if(expected_words>out_words&&m_ready)begin age<=age+1;if(age>50)begin $display("PROTOCOL VIOLATION [AXIS_FORWARD_PROGRESS]: bounded latency exceeded");errors=errors+1;age<=0;end end
      prev_stall<=m_valid&&!m_ready;prev_data<=m_data;prev_keep<=m_keep;prev_last<=m_last;
    end
  end
  task send_byte;
    input [7:0] d;input last;
    begin @(negedge clk);s_data=d;s_last=last;s_valid=1;while(!s_ready)@(negedge clk);
      @(negedge clk);s_valid=0;s_last=0;end
  endtask
  task queue_word;
    input [31:0] d;input [3:0] k;
    begin expected_data[expected_words]=d;expected_keep[expected_words]=k;expected_words=expected_words+1;end
  endtask
  initial begin
    errors=0;in_beats=0;out_words=0;expected_words=0;age=0;clk=0;rst=1;
    s_valid=0;s_last=0;s_data=0;m_ready=0;prev_stall=0;
    repeat(4)@(posedge clk);rst=0;
    queue_word(32'h13121110,4'hf);queue_word(32'h17161514,4'hf);
    queue_word(32'h00003130,4'h3);
    fork
      begin
        for(i=0;i<8;i=i+1)send_byte(8'h10+i,(i%4)==3);
        send_byte(8'h30,0);send_byte(8'h31,1);
      end
      begin for(j=0;j<70;j=j+1)begin @(negedge clk);m_ready=(j%6)>1;end m_ready=1;end
    join
    while(out_words<expected_words)@(posedge clk);
    m_ready=0;send_byte(8'hee,1);repeat(2)@(posedge clk);rst=1;s_valid=0;
    repeat(3)@(posedge clk);rst=0;in_beats=0;out_words=0;expected_words=0;age=0;m_ready=1;
    queue_word(32'h0000005a,4'h1);send_byte(8'h5a,1);while(out_words<1)@(posedge clk);
    if(out_words!=expected_words)begin $display("PROTOCOL VIOLATION [AXIS_TRANSACTION_CONSERVATION]: output word count differs from expected");errors=errors+1;end
    if(errors==0)$display("AXIS ADAPTER ENHANCED: ALL TESTS PASSED");else $display("AXIS ADAPTER ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #60000;$display("AXIS ADAPTER ENHANCED: TIMEOUT");$finish;end
endmodule
