`timescale 1ns/1ps
module apb_cdc_tb;
  integer errors, src_req, src_rsp, dst_req, age, i;
  reg src_clk, dst_clk, src_rst_n, dst_rst_n;
  reg src_psel, src_penable, src_pwrite;
  reg [7:0] src_paddr;
  reg [31:0] src_pwdata;
  wire src_pready, src_pslverr;
  wire [31:0] src_prdata;
  wire dst_psel, dst_penable, dst_pwrite;
  wire [7:0] dst_paddr;
  wire [31:0] dst_pwdata;
  reg dst_pready;
  reg [31:0] dst_prdata;
  reg dst_pslverr;
  reg [31:0] mem [0:15];
  reg prev_dst_wait;
  reg [7:0] prev_dst_addr;
  reg [31:0] prev_dst_data;
  reg prev_dst_write;

  always #5 src_clk = ~src_clk;
  always #8 dst_clk = ~dst_clk;

  apb_cdc #(.ADDR_WIDTH(8), .DATA_WIDTH(32), .LOG_DEPTH(1)) dut (
    .src_pclk_i(src_clk), .src_preset_ni(src_rst_n),
    .src_psel_i(src_psel), .src_penable_i(src_penable),
    .src_pwrite_i(src_pwrite), .src_paddr_i(src_paddr),
    .src_pwdata_i(src_pwdata), .src_pstrb_i(4'hf), .src_pprot_i(3'b0),
    .src_pready_o(src_pready), .src_prdata_o(src_prdata),
    .src_pslverr_o(src_pslverr), .dst_pclk_i(dst_clk),
    .dst_preset_ni(dst_rst_n), .dst_psel_o(dst_psel),
    .dst_penable_o(dst_penable), .dst_pwrite_o(dst_pwrite),
    .dst_paddr_o(dst_paddr), .dst_pwdata_o(dst_pwdata),
    .dst_pstrb_o(), .dst_pprot_o(), .dst_pready_i(dst_pready),
    .dst_prdata_i(dst_prdata), .dst_pslverr_i(dst_pslverr)
  );

  always @(posedge dst_clk) begin
    if (!dst_rst_n) begin
      dst_pready <= 0;
      dst_pslverr <= 0;
    end else begin
      dst_pready <= dst_psel && dst_penable && (i[1:0] != 2'b01);
      i <= i + 1;
      if (dst_psel && dst_penable && dst_pready) begin
        dst_req = dst_req + 1;
        if (dst_pwrite) mem[dst_paddr[5:2]] <= dst_pwdata;
      end
      dst_prdata <= mem[dst_paddr[5:2]];
      if (prev_dst_wait &&
          (!dst_psel || !dst_penable || dst_paddr !== prev_dst_addr ||
           dst_pwdata !== prev_dst_data || dst_pwrite !== prev_dst_write)) begin
        $display("CDC/RESET VIOLATION [APB_STALL_STABILITY]: destination payload changed while stalled");
        errors = errors + 1;
      end
      if ((dst_psel || dst_penable) &&
          ((^dst_paddr === 1'bx) || (^dst_pwrite === 1'bx))) begin
        $display("CDC/RESET VIOLATION [APB_REQUEST_KNOWN]: X on active destination request");
        errors = errors + 1;
      end
      prev_dst_wait <= dst_psel && dst_penable && !dst_pready;
      prev_dst_addr <= dst_paddr;
      prev_dst_data <= dst_pwdata;
      prev_dst_write <= dst_pwrite;
    end
  end

  always @(posedge src_clk) begin
    if (!src_rst_n) age <= 0;
    else begin
      if (src_psel && !src_penable) src_req = src_req + 1;
      if (src_pready) begin
        src_rsp = src_rsp + 1;
        age <= 0;
        if (src_rsp > src_req) begin
          $display("CDC/RESET VIOLATION [APB_RESPONSE_COHERENCY]: response without request");
          errors = errors + 1;
        end
        if ((^src_prdata === 1'bx) || (^src_pslverr === 1'bx)) begin
          $display("CDC/RESET VIOLATION [APB_RESPONSE_KNOWN]: X in response");
          errors = errors + 1;
        end
      end else if (src_psel && src_penable) begin
        age <= age + 1;
        if (age > 80) begin
          $display("CDC/RESET VIOLATION [APB_CROSS_DOMAIN_LATENCY]: bounded latency exceeded");
          errors = errors + 1;
          age <= 0;
        end
      end
    end
  end

  task apb_write;
    input [7:0] a; input [31:0] d;
    begin
      @(negedge src_clk); src_paddr=a; src_pwdata=d; src_pwrite=1;
      src_psel=1; src_penable=0;
      @(negedge src_clk); src_penable=1;
      while (!src_pready) @(negedge src_clk);
      @(negedge src_clk); src_psel=0; src_penable=0; src_pwrite=0;
    end
  endtask
  task apb_read_check;
    input [7:0] a; input [31:0] expected;
    begin
      @(negedge src_clk); src_paddr=a; src_pwrite=0; src_psel=1; src_penable=0;
      @(negedge src_clk); src_penable=1;
      while (!src_pready) @(negedge src_clk);
      if (src_prdata !== expected) begin
        $display("CDC/RESET VIOLATION [APB_DATA_COHERENCY]: read %h expected %h",src_prdata,expected);
        errors=errors+1;
      end
      @(negedge src_clk); src_psel=0; src_penable=0;
    end
  endtask

  initial begin
    errors=0; src_req=0; src_rsp=0; dst_req=0; age=0; i=0;
    src_clk=0; dst_clk=0; src_rst_n=0; dst_rst_n=0;
    src_psel=0; src_penable=0; src_pwrite=0; src_paddr=0; src_pwdata=0;
    dst_pready=0; dst_prdata=0; dst_pslverr=0; prev_dst_wait=0;
    for (i=0;i<16;i=i+1) mem[i]=0;
    i=0;
    repeat(5) @(posedge src_clk); src_rst_n=1;
    repeat(4) @(posedge dst_clk); dst_rst_n=1;
    apb_write(8'h04,32'ha5a51234);
    apb_read_check(8'h04,32'ha5a51234);
    apb_write(8'h08,32'h55aa00ff);
    apb_read_check(8'h08,32'h55aa00ff);
    /* Exercise each reset domain independently while the bridge is idle. */
    dst_rst_n=0; repeat(3) @(posedge dst_clk); dst_rst_n=1;
    repeat(5) @(posedge src_clk);
    src_rst_n=0; repeat(3) @(posedge src_clk); src_rst_n=1;
    repeat(5) @(posedge dst_clk);
    src_req=0; src_rsp=0; dst_req=0;
    fork
      begin
        @(negedge src_clk); src_paddr=8'h0c; src_pwdata=32'hdeadbeef;
        src_pwrite=1; src_psel=1; src_penable=0;
        @(negedge src_clk); src_penable=1;
      end
      begin
        repeat(3) @(posedge dst_clk); src_rst_n=0; dst_rst_n=0;
        src_psel=0; src_penable=0; src_pwrite=0;
        repeat(4) @(posedge dst_clk); dst_rst_n=1;
        repeat(4) @(posedge src_clk); src_rst_n=1;
      end
    join
    src_req=0; src_rsp=0; dst_req=0;
    repeat(8) @(posedge src_clk);
    apb_write(8'h0c,32'hcafef00d);
    apb_read_check(8'h0c,32'hcafef00d);
    if (src_req != src_rsp || src_req != dst_req) begin
      $display("CDC/RESET VIOLATION [APB_TRANSACTION_CONSERVATION]: src_req=%0d rsp=%0d dst=%0d",
               src_req,src_rsp,dst_req); errors=errors+1;
    end
    if (errors==0) $display("APB CDC ENHANCED: ALL TESTS PASSED");
    else $display("APB CDC ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #120000; $display("APB CDC ENHANCED: TIMEOUT"); $finish; end
endmodule
