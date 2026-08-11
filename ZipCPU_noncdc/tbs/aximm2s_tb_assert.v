`timescale 1ns/1ps
// Assertion-enhanced starter testbench generated for simulation + protocol checking.

module aximm2s_assert;
    localparam C_AXI_ADDR_WIDTH = 8;
    localparam C_AXI_DATA_WIDTH = 32;
    localparam C_AXI_ID_WIDTH   = 1;

    reg clk = 0;
    reg rstn = 0;
    always #5 clk = ~clk;

    wire                        M_AXIS_TVALID;
    reg                         M_AXIS_TREADY;
    wire [C_AXI_DATA_WIDTH-1:0] M_AXIS_TDATA;
    wire                        M_AXIS_TLAST;

    reg                         S_AXIL_AWVALID;
    wire                        S_AXIL_AWREADY;
    reg  [4:0]                  S_AXIL_AWADDR;
    reg  [2:0]                  S_AXIL_AWPROT;
    reg                         S_AXIL_WVALID;
    wire                        S_AXIL_WREADY;
    reg  [31:0]                 S_AXIL_WDATA;
    reg  [3:0]                  S_AXIL_WSTRB;
    wire                        S_AXIL_BVALID;
    reg                         S_AXIL_BREADY;
    wire [1:0]                  S_AXIL_BRESP;
    reg                         S_AXIL_ARVALID;
    wire                        S_AXIL_ARREADY;
    reg  [4:0]                  S_AXIL_ARADDR;
    reg  [2:0]                  S_AXIL_ARPROT;
    wire                        S_AXIL_RVALID;
    reg                         S_AXIL_RREADY;
    wire [31:0]                 S_AXIL_RDATA;
    wire [1:0]                  S_AXIL_RRESP;

    wire                        M_AXI_ARVALID;
    reg                         M_AXI_ARREADY;
    wire [C_AXI_ID_WIDTH-1:0]   M_AXI_ARID;
    wire [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR;
    wire [7:0]                  M_AXI_ARLEN;
    wire [2:0]                  M_AXI_ARSIZE;
    wire [1:0]                  M_AXI_ARBURST;
    wire                        M_AXI_ARLOCK;
    wire [3:0]                  M_AXI_ARCACHE;
    wire [2:0]                  M_AXI_ARPROT;
    wire [3:0]                  M_AXI_ARQOS;
    reg                         M_AXI_RVALID;
    wire                        M_AXI_RREADY;
    reg  [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA;
    reg                         M_AXI_RLAST;
    reg  [C_AXI_ID_WIDTH-1:0]   M_AXI_RID;
    reg  [1:0]                  M_AXI_RRESP;
    wire                        o_int;

    integer errors, idx, recv_count;
    reg [31:0] mem [0:63];
    reg [31:0] expected [0:3];
    reg [7:0] read_addr;
    reg [7:0] read_len;
    integer read_beat;
    reg sending;
    reg [7:0] lfsr;

    aximm2s #(
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH), .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH), .OPT_TLAST(1), .LGFIFO(4), .LGLEN(8), .OPT_LOWPOWER(0)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
        .M_AXIS_TVALID(M_AXIS_TVALID), .M_AXIS_TREADY(M_AXIS_TREADY), .M_AXIS_TDATA(M_AXIS_TDATA), .M_AXIS_TLAST(M_AXIS_TLAST),
        .S_AXIL_AWVALID(S_AXIL_AWVALID), .S_AXIL_AWREADY(S_AXIL_AWREADY), .S_AXIL_AWADDR(S_AXIL_AWADDR), .S_AXIL_AWPROT(S_AXIL_AWPROT),
        .S_AXIL_WVALID(S_AXIL_WVALID), .S_AXIL_WREADY(S_AXIL_WREADY), .S_AXIL_WDATA(S_AXIL_WDATA), .S_AXIL_WSTRB(S_AXIL_WSTRB),
        .S_AXIL_BVALID(S_AXIL_BVALID), .S_AXIL_BREADY(S_AXIL_BREADY), .S_AXIL_BRESP(S_AXIL_BRESP),
        .S_AXIL_ARVALID(S_AXIL_ARVALID), .S_AXIL_ARREADY(S_AXIL_ARREADY), .S_AXIL_ARADDR(S_AXIL_ARADDR), .S_AXIL_ARPROT(S_AXIL_ARPROT),
        .S_AXIL_RVALID(S_AXIL_RVALID), .S_AXIL_RREADY(S_AXIL_RREADY), .S_AXIL_RDATA(S_AXIL_RDATA), .S_AXIL_RRESP(S_AXIL_RRESP),
        .M_AXI_ARVALID(M_AXI_ARVALID), .M_AXI_ARREADY(M_AXI_ARREADY), .M_AXI_ARID(M_AXI_ARID), .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN), .M_AXI_ARSIZE(M_AXI_ARSIZE), .M_AXI_ARBURST(M_AXI_ARBURST), .M_AXI_ARLOCK(M_AXI_ARLOCK),
        .M_AXI_ARCACHE(M_AXI_ARCACHE), .M_AXI_ARPROT(M_AXI_ARPROT), .M_AXI_ARQOS(M_AXI_ARQOS),
        .M_AXI_RVALID(M_AXI_RVALID), .M_AXI_RREADY(M_AXI_RREADY), .M_AXI_RDATA(M_AXI_RDATA), .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RID(M_AXI_RID), .M_AXI_RRESP(M_AXI_RRESP), .o_int(o_int)
    );

    // Random-ish AXI-stream backpressure
    always @(posedge clk) begin
        if (!rstn) begin lfsr <= 8'hac; M_AXIS_TREADY <= 1'b0; end
        else begin lfsr <= {lfsr[6:0], lfsr[7]^lfsr[5]^lfsr[4]^lfsr[3]}; M_AXIS_TREADY <= lfsr[1] | lfsr[0]; end
    end

    // Simple AXI RAM read model
    always @(posedge clk) begin
        if (!rstn) begin
            M_AXI_ARREADY <= 1'b0; M_AXI_RVALID <= 1'b0; M_AXI_RDATA <= 0; M_AXI_RLAST <= 0; M_AXI_RID <= 0; M_AXI_RRESP <= 0;
            sending <= 0; read_addr <= 0; read_len <= 0; read_beat <= 0;
        end else begin
            M_AXI_ARREADY <= !sending;
            if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                read_addr <= M_AXI_ARADDR;
                read_len  <= M_AXI_ARLEN;
                read_beat <= 0;
                sending   <= 1;
                M_AXI_RVALID <= 1;
                M_AXI_RDATA  <= mem[M_AXI_ARADDR >> 2];
                M_AXI_RLAST  <= (M_AXI_ARLEN == 0);
                M_AXI_RID    <= M_AXI_ARID;
                M_AXI_RRESP  <= 0;
            end else if (M_AXI_RVALID && M_AXI_RREADY) begin
                if (M_AXI_RLAST) begin
                    M_AXI_RVALID <= 0; M_AXI_RLAST <= 0; sending <= 0;
                end else begin
                    read_beat <= read_beat + 1;
                    M_AXI_RDATA <= mem[(read_addr >> 2) + read_beat + 1];
                    M_AXI_RLAST <= (read_beat + 1 == read_len);
                end
            end
        end
    end

    task axil_write;
        input [4:0] addr; input [31:0] data;
        begin
            @(negedge clk); S_AXIL_AWADDR=addr; S_AXIL_WDATA=data; S_AXIL_WSTRB=4'hf; S_AXIL_AWVALID=1; S_AXIL_WVALID=1; S_AXIL_BREADY=1;
            wait(S_AXIL_AWREADY && S_AXIL_WREADY);
            @(negedge clk); S_AXIL_AWVALID=0; S_AXIL_WVALID=0;
            wait(S_AXIL_BVALID); @(negedge clk); S_AXIL_BREADY=0;
        end
    endtask

    initial begin
        errors=0; recv_count=0;
        for (idx=0; idx<64; idx=idx+1) mem[idx]=0;
        mem[4]=32'hAAAA_0001; mem[5]=32'hBBBB_0002; mem[6]=32'hCCCC_0003; mem[7]=32'hDDDD_0004;
        expected[0]=mem[4]; expected[1]=mem[5]; expected[2]=mem[6]; expected[3]=mem[7];
        S_AXIL_AWVALID=0; S_AXIL_AWADDR=0; S_AXIL_AWPROT=0; S_AXIL_WVALID=0; S_AXIL_WDATA=0; S_AXIL_WSTRB=0;
        S_AXIL_BREADY=0; S_AXIL_ARVALID=0; S_AXIL_ARADDR=0; S_AXIL_ARPROT=0; S_AXIL_RREADY=0;
        repeat(5) @(posedge clk); rstn=1; repeat(5) @(posedge clk);
        $display("TEST AXIMM2S with random stream backpressure");
        axil_write(5'h08, 32'h0000_0010); // source address
        axil_write(5'h18, 32'd16);        // 16 bytes
        axil_write(5'h00, 32'hC000_0000); // start and clear error
        repeat(300) @(posedge clk);
        if (recv_count != 4) begin $display("FAIL recv_count=%0d expected=4", recv_count); errors=errors+1; end
        if (errors==0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (rstn && M_AXIS_TVALID && M_AXIS_TREADY) begin
            if (M_AXIS_TDATA !== expected[recv_count]) begin $display("FAIL stream[%0d]=%h expected=%h", recv_count, M_AXIS_TDATA, expected[recv_count]); errors=errors+1; end
            else $display("PASS stream[%0d]=%h", recv_count, M_AXIS_TDATA);
            if (recv_count == 3 && !M_AXIS_TLAST) begin $display("FAIL missing TLAST"); errors=errors+1; end
            recv_count <= recv_count + 1;
        end
    end


  // ---------------- Assertion monitors ----------------
  // VALID must remain asserted until READY for AXI-Lite address/data channels
  reg prev_aw_wait, prev_w_wait, prev_ar_wait;
  always @(posedge clk) begin
    if (!rstn) begin
      prev_aw_wait <= 1'b0; prev_w_wait <= 1'b0; prev_ar_wait <= 1'b0;
    end else begin
      if (prev_aw_wait) if (!(S_AXIL_AWVALID) else begin $display("ASSERT FAIL: AWVALID dropped before AWREADY")) begin $display("ASSERT FAIL: S_AXIL_AWVALID) else begin $display("ASSERT FAIL: AWVALID dropped before AWREADY""); errors = errors + 1; end errors = errors + 1; end
      if (prev_w_wait)  if (!(S_AXIL_WVALID)  else begin $display("ASSERT FAIL: WVALID dropped before WREADY")) begin $display("ASSERT FAIL: S_AXIL_WVALID)  else begin $display("ASSERT FAIL: WVALID dropped before WREADY""); errors = errors + 1; end errors = errors + 1; end
      if (prev_ar_wait) if (!(S_AXIL_ARVALID) else begin $display("ASSERT FAIL: ARVALID dropped before ARREADY")) begin $display("ASSERT FAIL: S_AXIL_ARVALID) else begin $display("ASSERT FAIL: ARVALID dropped before ARREADY""); errors = errors + 1; end errors = errors + 1; end
      prev_aw_wait <= (S_AXIL_AWVALID && !S_AXIL_AWREADY);
      prev_w_wait  <= (S_AXIL_WVALID  && !S_AXIL_WREADY);
      prev_ar_wait <= (S_AXIL_ARVALID && !S_AXIL_ARREADY);
    end
  end


  // ---------------- Assertion monitors ----------------
  // AXI-Stream payload must remain stable while TVALID is high and TREADY is low
  reg prev_stream_wait;
  reg [31:0] prev_stream_data;
  reg prev_stream_last;
  always @(posedge clk) begin
    if (!rstn) begin
      prev_stream_wait <= 1'b0; prev_stream_data <= 0; prev_stream_last <= 1'b0;
    end else begin
      if (prev_stream_wait) begin
        if (!(M_AXIS_TVALID) else begin $display("ASSERT FAIL: TVALID dropped before TREADY")) begin $display("ASSERT FAIL: M_AXIS_TVALID) else begin $display("ASSERT FAIL: TVALID dropped before TREADY""); errors = errors + 1; end errors = errors + 1; end
        if (!(M_AXIS_TDATA == prev_stream_data) else begin $display("ASSERT FAIL: TDATA changed while stalled")) begin $display("ASSERT FAIL: M_AXIS_TDATA == prev_stream_data) else begin $display("ASSERT FAIL: TDATA changed while stalled""); errors = errors + 1; end errors = errors + 1; end
        if (!(M_AXIS_TLAST == prev_stream_last) else begin $display("ASSERT FAIL: TLAST changed while stalled")) begin $display("ASSERT FAIL: M_AXIS_TLAST == prev_stream_last) else begin $display("ASSERT FAIL: TLAST changed while stalled""); errors = errors + 1; end errors = errors + 1; end
      end
      prev_stream_wait <= (M_AXIS_TVALID && !M_AXIS_TREADY);
      prev_stream_data <= M_AXIS_TDATA;
      prev_stream_last <= M_AXIS_TLAST;
    end
  end

endmodule
