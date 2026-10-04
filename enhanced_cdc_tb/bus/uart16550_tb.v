`timescale 1ns/1ps
module uart16550_tb;
  integer errors,requests,responses,age,spins;
  reg wb_clk_i,wb_rst_i,wb_we_i,wb_stb_i,wb_cyc_i;
  reg [2:0] wb_adr_i;
  reg [7:0] wb_dat_i;
  wire [7:0] wb_dat_o;
  wire wb_ack_o,int_o,stx,rts,dtr;
  reg prev_wait,prev_we;
  reg [2:0] prev_addr;
  reg [7:0] prev_data;
  reg [7:0] lsr,rxb;
  always #5 wb_clk_i=~wb_clk_i;
  uart_top dut(.wb_clk_i(wb_clk_i),.wb_rst_i(wb_rst_i),
    .wb_adr_i(wb_adr_i),.wb_dat_i(wb_dat_i),.wb_dat_o(wb_dat_o),
    .wb_we_i(wb_we_i),.wb_stb_i(wb_stb_i),.wb_cyc_i(wb_cyc_i),
    .wb_ack_o(wb_ack_o),.wb_sel_i(4'b0001),.int_o(int_o),
    .stx_pad_o(stx),.srx_pad_i(stx),.rts_pad_o(rts),
    .cts_pad_i(1'b1),.dtr_pad_o(dtr),.dsr_pad_i(1'b1),
    .ri_pad_i(1'b1),.dcd_pad_i(1'b1));
  always @(posedge wb_clk_i) begin
    if(wb_rst_i)begin prev_wait<=0;age<=0;end
    else begin
      if(wb_cyc_i&&wb_stb_i&&!prev_wait)begin requests=requests+1;age<=1;end
      if(wb_ack_o)begin
        responses=responses+1;age<=0;
        if(!wb_cyc_i)begin $display("PROTOCOL VIOLATION [WB_ACK_WITHOUT_CYCLE]: ACK asserted without CYC");errors=errors+1;end
        if(responses>requests)begin $display("PROTOCOL VIOLATION [WB_RESPONSE_WITHOUT_REQUEST]: response without request");errors=errors+1;end
        if(!wb_we_i&&^wb_dat_o===1'bx)begin $display("PROTOCOL VIOLATION [WB_RESPONSE_KNOWN]: X in bus response");errors=errors+1;end
      end
      if(prev_wait&&!wb_ack_o&&(!wb_cyc_i||!wb_stb_i||wb_adr_i!==prev_addr||
         wb_dat_i!==prev_data||wb_we_i!==prev_we))begin $display("PROTOCOL VIOLATION [WB_STALL_STABILITY]: request changed while stalled");errors=errors+1;end
      if(requests>responses)begin age<=age+1;if(age>20)begin $display("PROTOCOL VIOLATION [WB_RESPONSE_LATENCY]: bounded bus latency exceeded");errors=errors+1;age<=0;end end
      prev_wait<=wb_cyc_i&&wb_stb_i&&!wb_ack_o;prev_addr<=wb_adr_i;prev_data<=wb_dat_i;prev_we<=wb_we_i;
    end
  end
  task wb_write;
    input [2:0] a;input [7:0] d;
    begin @(negedge wb_clk_i);wb_adr_i=a;wb_dat_i=d;wb_we_i=1;wb_stb_i=1;wb_cyc_i=1;
      while(!wb_ack_o)@(negedge wb_clk_i);
      @(negedge wb_clk_i);wb_we_i=0;wb_stb_i=0;wb_cyc_i=0;end
  endtask
  task wb_read;
    input [2:0] a;output [7:0] d;
    begin @(negedge wb_clk_i);wb_adr_i=a;wb_we_i=0;wb_stb_i=1;wb_cyc_i=1;
      while(!wb_ack_o)@(negedge wb_clk_i);d=wb_dat_o;
      @(negedge wb_clk_i);wb_stb_i=0;wb_cyc_i=0;end
  endtask
  task configure;
    begin wb_write(3,8'h80);wb_write(0,8'h01);wb_write(1,8'h00);
      wb_write(3,8'h03);wb_write(2,8'h07);wb_write(4,8'h00);end
  endtask
  task loopback;
    input [7:0] d;
    begin
      wb_write(0,d);spins=0;lsr=0;
      while(lsr[0]!==1'b1&&spins<5000)begin wb_read(5,lsr);spins=spins+1;end
      if(lsr[0]!==1'b1)begin $display("PROTOCOL VIOLATION [UART_RECEIVE_COMPLETION]: receive did not complete");errors=errors+1;end
      else begin wb_read(0,rxb);if(rxb!==d)begin $display("PROTOCOL VIOLATION [UART_LOOPBACK_DATA]: loopback %h expected %h",rxb,d);errors=errors+1;end end
    end
  endtask
  initial begin
    errors=0;requests=0;responses=0;age=0;wb_clk_i=0;wb_rst_i=1;wb_we_i=0;wb_stb_i=0;wb_cyc_i=0;wb_adr_i=0;wb_dat_i=0;prev_wait=0;
    repeat(8)@(posedge wb_clk_i);wb_rst_i=0;repeat(4)@(posedge wb_clk_i);
    if(stx!==1'b1)begin $display("PROTOCOL VIOLATION [UART_TX_IDLE_LEVEL]: TX is not idle high");errors=errors+1;end
    configure;loopback(8'h5a);loopback(8'ha5);
    @(negedge wb_clk_i);wb_adr_i=0;wb_dat_i=8'hee;wb_we_i=1;wb_stb_i=1;wb_cyc_i=1;
    @(posedge wb_clk_i);wb_rst_i=1;wb_stb_i=0;wb_cyc_i=0;wb_we_i=0;
    repeat(8)@(posedge wb_clk_i);wb_rst_i=0;requests=0;responses=0;age=0;repeat(4)@(posedge wb_clk_i);
    configure;loopback(8'h3c);
    if(requests!=responses)begin $display("PROTOCOL VIOLATION [WB_TRANSACTION_CONSERVATION]: requests=%0d responses=%0d",requests,responses);errors=errors+1;end
    if(errors==0)$display("UART16550 ENHANCED: ALL TESTS PASSED");else $display("UART16550 ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #450000;$display("UART16550 ENHANCED: TIMEOUT");$finish;end
endmodule
