`timescale 1ns/1ps
module i2c_master_tb;
  integer errors,commands,received,age;
  reg clk,rst,cmd_write,cmd_stop,cmd_valid,wr_valid,wr_last;
  reg [6:0] cmd_addr;
  reg [7:0] wr_data;
  wire cmd_ready,wr_ready,busy,missed_ack;
  wire scl_m_o,sda_m_o,scl_s_o,sda_s_o,scl,sda;
  wire [7:0] slv_data;
  wire slv_valid;
  reg pcmd,pwr;
  reg [6:0] pcmd_addr;
  reg [7:0] pwr_data;
  reg [7:0] expected[0:7];
  always #5 clk=~clk;
  assign scl=scl_m_o&scl_s_o;
  assign sda=sda_m_o&sda_s_o;
  i2c_master dut(.clk(clk),.rst(rst),.s_axis_cmd_address(cmd_addr),
    .s_axis_cmd_start(1'b0),.s_axis_cmd_read(1'b0),.s_axis_cmd_write(cmd_write),
    .s_axis_cmd_write_multiple(1'b0),.s_axis_cmd_stop(cmd_stop),
    .s_axis_cmd_valid(cmd_valid),.s_axis_cmd_ready(cmd_ready),
    .s_axis_data_tdata(wr_data),.s_axis_data_tvalid(wr_valid),
    .s_axis_data_tready(wr_ready),.s_axis_data_tlast(wr_last),
    .m_axis_data_tdata(),.m_axis_data_tvalid(),.m_axis_data_tready(1'b1),
    .m_axis_data_tlast(),.scl_i(scl),.scl_o(scl_m_o),.scl_t(),
    .sda_i(sda),.sda_o(sda_m_o),.sda_t(),.busy(busy),
    .bus_control(),.bus_active(),.missed_ack(missed_ack),
    .prescale(16'd8),.stop_on_idle(1'b0));
  i2c_slave #(.FILTER_LEN(1)) slave(.clk(clk),.rst(rst),.release_bus(1'b0),
    .s_axis_data_tdata(8'h0),.s_axis_data_tvalid(1'b0),.s_axis_data_tready(),
    .s_axis_data_tlast(1'b0),.m_axis_data_tdata(slv_data),
    .m_axis_data_tvalid(slv_valid),.m_axis_data_tready(1'b1),
    .m_axis_data_tlast(),.scl_i(scl),.scl_o(scl_s_o),.scl_t(),
    .sda_i(sda),.sda_o(sda_s_o),.sda_t(),.busy(),.bus_address(),
    .bus_addressed(),.bus_active(),.enable(1'b1),
    .device_address(7'h50),.device_address_mask(7'h7f));
  always @(posedge clk) begin
    if(rst)begin pcmd<=0;pwr<=0;age<=0;end
    else begin
      if(cmd_valid&&cmd_ready)begin expected[commands]=wr_data;commands=commands+1;age<=1;end
      if(slv_valid)begin
        if(received>=commands)begin $display("PROTOCOL VIOLATION [I2C_RECEIVE_WITHOUT_COMMAND]: receive without command");errors=errors+1;end
        else if(slv_data!==expected[received])begin $display("PROTOCOL VIOLATION [I2C_RECEIVE_DATA]: data %h expected %h",slv_data,expected[received]);errors=errors+1;end
        received=received+1;age<=0;
      end
      if(pcmd&&(!cmd_valid||cmd_addr!==pcmd_addr))begin $display("PROTOCOL VIOLATION [I2C_COMMAND_STABILITY]: command changed while stalled");errors=errors+1;end
      if(pwr&&(!wr_valid||wr_data!==pwr_data))begin $display("PROTOCOL VIOLATION [I2C_WRITE_DATA_STABILITY]: write data changed while stalled");errors=errors+1;end
      if(slv_valid&&^slv_data===1'bx)begin $display("PROTOCOL VIOLATION [I2C_RECEIVE_DATA_KNOWN]: X in receive data");errors=errors+1;end
      if(commands>received)begin age<=age+1;if(age>3000)begin $display("PROTOCOL VIOLATION [I2C_COMPLETION_LATENCY]: bounded completion exceeded");errors=errors+1;age<=0;end end
      pcmd<=cmd_valid&&!cmd_ready;pwr<=wr_valid&&!wr_ready;pcmd_addr<=cmd_addr;pwr_data<=wr_data;
    end
  end
  task write_byte;
    input [7:0] d;
    begin
      @(negedge clk);wr_data=d;wr_last=1;wr_valid=1;cmd_addr=7'h50;cmd_write=1;cmd_stop=1;cmd_valid=1;
      while(!cmd_ready)@(negedge clk);@(negedge clk);cmd_valid=0;cmd_write=0;cmd_stop=0;
      while(!wr_ready)@(negedge clk);@(negedge clk);wr_valid=0;wr_last=0;
      while(received<commands)@(posedge clk);while(busy)@(posedge clk);
      if(missed_ack)begin $display("PROTOCOL VIOLATION [I2C_ACKNOWLEDGE]: expected ACK was not observed");errors=errors+1;end
    end
  endtask
  initial begin
    errors=0;commands=0;received=0;age=0;clk=0;rst=1;cmd_write=0;cmd_stop=0;cmd_valid=0;cmd_addr=7'h50;
    wr_valid=0;wr_last=0;wr_data=0;pcmd=0;pwr=0;
    repeat(5)@(posedge clk);rst=0;repeat(8)@(posedge clk);
    write_byte(8'ha5);write_byte(8'h3c);
    @(negedge clk);wr_data=8'hee;wr_last=1;wr_valid=1;cmd_write=1;cmd_stop=1;cmd_valid=1;
    while(!cmd_ready)@(negedge clk);@(negedge clk);cmd_valid=0;
    repeat(20)@(posedge clk);rst=1;wr_valid=0;cmd_write=0;cmd_stop=0;
    repeat(5)@(posedge clk);rst=0;commands=0;received=0;age=0;repeat(8)@(posedge clk);
    write_byte(8'h5a);
    if(commands!=received)begin $display("PROTOCOL VIOLATION [I2C_TRANSACTION_CONSERVATION]: commands=%0d received=%0d",commands,received);errors=errors+1;end
    if(errors==0)$display("I2C MASTER ENHANCED: ALL TESTS PASSED");else $display("I2C MASTER ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #350000;$display("I2C MASTER ENHANCED: TIMEOUT");$finish;end
endmodule
