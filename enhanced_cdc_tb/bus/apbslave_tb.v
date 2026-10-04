`timescale 1ns/1ps
module apbslave_tb;
  integer errors,requests,responses,age,i;
  reg PCLK,PRESETn,PSEL,PENABLE,PWRITE;
  reg [11:0] PADDR;
  reg [31:0] PWDATA;
  reg [3:0] PWSTRB;
  wire PREADY,PSLVERR;
  wire [31:0] PRDATA;
  reg prev_wait,prev_write;
  reg [11:0] prev_addr;
  reg [31:0] prev_data;
  always #5 PCLK=~PCLK;
  apbslave dut(.PCLK(PCLK),.PRESETn(PRESETn),.PSEL(PSEL),.PENABLE(PENABLE),
    .PREADY(PREADY),.PADDR(PADDR),.PWRITE(PWRITE),.PWDATA(PWDATA),
    .PWSTRB(PWSTRB),.PPROT(3'b0),.PRDATA(PRDATA),.PSLVERR(PSLVERR));
  always @(posedge PCLK) begin
    if(!PRESETn)begin prev_wait<=0;age<=0;end
    else begin
      if(PSEL&&!PENABLE)begin requests=requests+1;age<=1;end
      if(PREADY)begin
        responses=responses+1;age<=0;
        if(responses>requests)begin $display("PROTOCOL VIOLATION [APB_RESPONSE_WITHOUT_REQUEST]: response without request");errors=errors+1;end
        if((!PWRITE&&(^PRDATA===1'bx))||(^PSLVERR===1'bx))begin $display("PROTOCOL VIOLATION [APB_RESPONSE_KNOWN]: X in response");errors=errors+1;end
      end
      if(PENABLE&&!PSEL)begin $display("PROTOCOL VIOLATION [APB_ENABLE_WITHOUT_SELECT]: PENABLE asserted without PSEL");errors=errors+1;end
      if(prev_wait&&(!PSEL||!PENABLE||PADDR!==prev_addr||PWDATA!==prev_data||PWRITE!==prev_write))begin
        $display("PROTOCOL VIOLATION [APB_STALL_STABILITY]: request changed while stalled");errors=errors+1;
      end
      if(PSEL&&PENABLE&&!PREADY)begin age<=age+1;if(age>20)begin $display("PROTOCOL VIOLATION [APB_RESPONSE_LATENCY]: bounded latency exceeded");errors=errors+1;age<=0;end end
      prev_wait<=PSEL&&PENABLE&&!PREADY;prev_addr<=PADDR;prev_data<=PWDATA;prev_write<=PWRITE;
    end
  end
  task apb_write;
    input [11:0] a;input [31:0] d;input [3:0] strb;
    begin @(negedge PCLK);PSEL=1;PENABLE=0;PWRITE=1;PADDR=a;PWDATA=d;PWSTRB=strb;
      @(negedge PCLK);PENABLE=1;while(!PREADY)@(negedge PCLK);
      @(negedge PCLK);PSEL=0;PENABLE=0;PWRITE=0;end
  endtask
  task apb_read_check;
    input [11:0] a;input [31:0] e;
    begin @(negedge PCLK);PSEL=1;PENABLE=0;PWRITE=0;PADDR=a;PWSTRB=0;
      @(negedge PCLK);PENABLE=1;while(!PREADY)@(negedge PCLK);
      if(PRDATA!==e)begin $display("PROTOCOL VIOLATION [APB_READ_DATA]: read %h expected %h",PRDATA,e);errors=errors+1;end
      @(negedge PCLK);PSEL=0;PENABLE=0;end
  endtask
  initial begin
    errors=0;requests=0;responses=0;age=0;PCLK=0;PRESETn=0;PSEL=0;PENABLE=0;PWRITE=0;PADDR=0;PWDATA=0;PWSTRB=0;prev_wait=0;
    repeat(4)@(posedge PCLK);PRESETn=1;
    apb_write(12'h004,32'h11223344,4'hf);apb_read_check(12'h004,32'h11223344);
    apb_write(12'h004,32'haabbccdd,4'b0011);apb_read_check(12'h004,32'h1122ccdd);
    @(negedge PCLK);PSEL=1;PENABLE=0;PWRITE=1;PADDR=12'h008;PWDATA=32'hdeadbeef;PWSTRB=4'hf;
    @(negedge PCLK);PENABLE=1;PRESETn=0;PSEL=0;PENABLE=0;
    repeat(3)@(posedge PCLK);PRESETn=1;requests=0;responses=0;
    apb_write(12'h008,32'hcafef00d,4'hf);apb_read_check(12'h008,32'hcafef00d);
    if(requests!=responses)begin $display("PROTOCOL VIOLATION [APB_TRANSACTION_CONSERVATION]: requests=%0d responses=%0d",requests,responses);errors=errors+1;end
    if(errors==0)$display("APBSLAVE ENHANCED: ALL TESTS PASSED");else $display("APBSLAVE ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #40000;$display("APBSLAVE ENHANCED: TIMEOUT");$finish;end
endmodule
