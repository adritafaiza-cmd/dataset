`timescale 1ns/1ps

module axis2mm_tb;
    localparam C_AXI_ADDR_WIDTH = 8;
    localparam C_AXI_DATA_WIDTH = 32;
    localparam C_AXI_ID_WIDTH   = 1;

    reg clk = 0;
    reg rstn = 0;
    always #5 clk = ~clk;

    // AXI-stream input
    reg                         S_AXIS_TVALID;
    wire                        S_AXIS_TREADY;
    reg  [C_AXI_DATA_WIDTH-1:0] S_AXIS_TDATA;
    reg                         S_AXIS_TLAST;
    reg                         S_AXIS_TUSER;

    // AXI-Lite control
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

    // AXI full write output
    wire                        M_AXI_AWVALID;
    reg                         M_AXI_AWREADY;
    wire [C_AXI_ID_WIDTH-1:0]   M_AXI_AWID;
    wire [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR;
    wire [7:0]                  M_AXI_AWLEN;
    wire [2:0]                  M_AXI_AWSIZE;
    wire [1:0]                  M_AXI_AWBURST;
    wire                        M_AXI_AWLOCK;
    wire [3:0]                  M_AXI_AWCACHE;
    wire [2:0]                  M_AXI_AWPROT;
    wire [3:0]                  M_AXI_AWQOS;
    wire                        M_AXI_WVALID;
    reg                         M_AXI_WREADY;
    wire [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA;
    wire [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB;
    wire                        M_AXI_WLAST;
    wire                        M_AXI_WUSER;
    reg                         M_AXI_BVALID;
    wire                        M_AXI_BREADY;
    reg  [C_AXI_ID_WIDTH-1:0]   M_AXI_BID;
    reg  [1:0]                  M_AXI_BRESP;
    wire                        o_int;

    integer errors;
    integer k;
    reg [31:0] mem [0:63];
    reg [C_AXI_ADDR_WIDTH-1:0] awaddr_hold;
    reg [7:0] awlen_hold;
    integer beat_count;

    axis2mm #(
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
        .C_AXIS_TUSER_WIDTH(0),
        .OPT_AXIS_SKIDBUFFER(0),
        .OPT_TLAST_SYNC(0),
        .LGFIFO(4),
        .LGLEN(8),
        .OPT_LOWPOWER(0)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
        .S_AXIS_TVALID(S_AXIS_TVALID), .S_AXIS_TREADY(S_AXIS_TREADY),
        .S_AXIS_TDATA(S_AXIS_TDATA), .S_AXIS_TLAST(S_AXIS_TLAST), .S_AXIS_TUSER(S_AXIS_TUSER),
        .S_AXIL_AWVALID(S_AXIL_AWVALID), .S_AXIL_AWREADY(S_AXIL_AWREADY), .S_AXIL_AWADDR(S_AXIL_AWADDR), .S_AXIL_AWPROT(S_AXIL_AWPROT),
        .S_AXIL_WVALID(S_AXIL_WVALID), .S_AXIL_WREADY(S_AXIL_WREADY), .S_AXIL_WDATA(S_AXIL_WDATA), .S_AXIL_WSTRB(S_AXIL_WSTRB),
        .S_AXIL_BVALID(S_AXIL_BVALID), .S_AXIL_BREADY(S_AXIL_BREADY), .S_AXIL_BRESP(S_AXIL_BRESP),
        .S_AXIL_ARVALID(S_AXIL_ARVALID), .S_AXIL_ARREADY(S_AXIL_ARREADY), .S_AXIL_ARADDR(S_AXIL_ARADDR), .S_AXIL_ARPROT(S_AXIL_ARPROT),
        .S_AXIL_RVALID(S_AXIL_RVALID), .S_AXIL_RREADY(S_AXIL_RREADY), .S_AXIL_RDATA(S_AXIL_RDATA), .S_AXIL_RRESP(S_AXIL_RRESP),
        .M_AXI_AWVALID(M_AXI_AWVALID), .M_AXI_AWREADY(M_AXI_AWREADY), .M_AXI_AWID(M_AXI_AWID), .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWLEN(M_AXI_AWLEN), .M_AXI_AWSIZE(M_AXI_AWSIZE), .M_AXI_AWBURST(M_AXI_AWBURST), .M_AXI_AWLOCK(M_AXI_AWLOCK),
        .M_AXI_AWCACHE(M_AXI_AWCACHE), .M_AXI_AWPROT(M_AXI_AWPROT), .M_AXI_AWQOS(M_AXI_AWQOS),
        .M_AXI_WVALID(M_AXI_WVALID), .M_AXI_WREADY(M_AXI_WREADY), .M_AXI_WDATA(M_AXI_WDATA), .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST), .M_AXI_WUSER(M_AXI_WUSER),
        .M_AXI_BVALID(M_AXI_BVALID), .M_AXI_BREADY(M_AXI_BREADY), .M_AXI_BID(M_AXI_BID), .M_AXI_BRESP(M_AXI_BRESP),
        .o_int(o_int)
    );

    // Very small AXI RAM write model
    always @(posedge clk) begin
        if (!rstn) begin
            M_AXI_AWREADY <= 1'b0;
            M_AXI_WREADY  <= 1'b0;
            M_AXI_BVALID  <= 1'b0;
            M_AXI_BRESP   <= 2'b00;
            M_AXI_BID     <= 0;
            beat_count    <= 0;
            awaddr_hold   <= 0;
            awlen_hold    <= 0;
        end else begin
            M_AXI_AWREADY <= 1'b1;
            M_AXI_WREADY  <= 1'b1;
            if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                awaddr_hold <= M_AXI_AWADDR;
                awlen_hold  <= M_AXI_AWLEN;
                beat_count  <= 0;
            end
            if (M_AXI_WVALID && M_AXI_WREADY) begin
                mem[(awaddr_hold >> 2) + beat_count] <= M_AXI_WDATA;
                beat_count <= beat_count + 1;
                if (M_AXI_WLAST) begin
                    M_AXI_BVALID <= 1'b1;
                    M_AXI_BRESP  <= 2'b00;
                    M_AXI_BID    <= 0;
                end
            end
            if (M_AXI_BVALID && M_AXI_BREADY)
                M_AXI_BVALID <= 1'b0;
        end
    end

    task axil_write;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            S_AXIL_AWADDR = addr; S_AXIL_WDATA = data; S_AXIL_WSTRB = 4'hf;
            S_AXIL_AWVALID = 1; S_AXIL_WVALID = 1; S_AXIL_BREADY = 1;
            wait(S_AXIL_AWREADY && S_AXIL_WREADY);
            @(negedge clk);
            S_AXIL_AWVALID = 0; S_AXIL_WVALID = 0;
            wait(S_AXIL_BVALID);
            @(negedge clk); S_AXIL_BREADY = 0;
        end
    endtask

    task stream_word;
        input [31:0] data;
        input last;
        begin
            @(negedge clk);
            S_AXIS_TDATA = data; S_AXIS_TLAST = last; S_AXIS_TVALID = 1;
            wait(S_AXIS_TREADY);
            @(negedge clk);
            S_AXIS_TVALID = 0; S_AXIS_TLAST = 0;
        end
    endtask

    initial begin
        errors = 0;
        for (k=0; k<64; k=k+1) mem[k] = 0;
        S_AXIS_TVALID=0; S_AXIS_TDATA=0; S_AXIS_TLAST=0; S_AXIS_TUSER=0;
        S_AXIL_AWVALID=0; S_AXIL_AWADDR=0; S_AXIL_AWPROT=0; S_AXIL_WVALID=0; S_AXIL_WDATA=0; S_AXIL_WSTRB=0;
        S_AXIL_BREADY=0; S_AXIL_ARVALID=0; S_AXIL_ARADDR=0; S_AXIL_ARPROT=0; S_AXIL_RREADY=0;
        repeat(5) @(posedge clk); rstn = 1; repeat(5) @(posedge clk);

        $display("TEST AXIS2MM with simple AXI RAM model");
        axil_write(5'h10, 32'h0000_0010); // destination address
        axil_write(5'h18, 32'd16);        // 16 bytes = 4 words
        axil_write(5'h00, 32'hC000_0000); // start and clear error

        stream_word(32'h1111_0001, 0);
        stream_word(32'h2222_0002, 0);
        stream_word(32'h3333_0003, 0);
        stream_word(32'h4444_0004, 1);

        repeat(80) @(posedge clk);
        if (mem[4] !== 32'h1111_0001) begin $display("FAIL mem[4]=%h", mem[4]); errors=errors+1; end
        if (mem[5] !== 32'h2222_0002) begin $display("FAIL mem[5]=%h", mem[5]); errors=errors+1; end
        if (mem[6] !== 32'h3333_0003) begin $display("FAIL mem[6]=%h", mem[6]); errors=errors+1; end
        if (mem[7] !== 32'h4444_0004) begin $display("FAIL mem[7]=%h", mem[7]); errors=errors+1; end

        if (errors == 0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors", errors);
        $finish;
    end
endmodule
