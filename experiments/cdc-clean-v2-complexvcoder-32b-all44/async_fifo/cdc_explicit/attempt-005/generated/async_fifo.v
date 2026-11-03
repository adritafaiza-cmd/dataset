module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    wire [ASIZE-1:0] w_gray_count;
    wire [ASIZE-1:0] r_gray_count;
    wire [ASIZE-1:0] w_bin_count;
    wire [ASIZE-1:0] r_bin_count;
    wire [ASIZE-1:0] r_gray_count_synced;
    wire [ASIZE-1:0] w_gray_count_synced;

    // Write gray counter
    gray_counter w_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_count(w_gray_count)
    );

    // Read gray counter
    gray_counter r_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_count(r_gray_count)
    );

    // Convert write gray count to binary
    gray_to_bin w_gray_to_bin (
        .gray_in(w_gray_count),
        .bin_out(w_bin_count)
    );

    // Convert read gray count to binary
    gray_to_bin r_gray_to_bin (
        .gray_in(r_gray_count),
        .bin_out(r_bin_count)
    );

    // Sync read gray count to write domain
    sync_gray_counter r_gray_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .gray_in(r_gray_count),
        .gray_out(r_gray_count_synced)
    );

    // Sync write gray count to read domain
    sync_gray_counter w_gray_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .gray_in(w_gray_count),
        .gray_out(w_gray_count_synced)
    );

    // Dual-port RAM
    dual_port_ram fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .waddr(w_bin_count),
        .raddr(r_bin_count)
    );

    // Calculate wfull and awfull
    wire [ASIZE:0] w_ptr_diff;
    wire [ASIZE:0] w_ptr_diff_synced;
    assign w_ptr_diff = w_bin_count - r_gray_count_synced;
    sync_gray_counter w_ptr_diff_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .gray_in(w_ptr_diff),
        .gray_out(w_ptr_diff_synced)
    );

    assign wfull = (w_ptr_diff_synced == (1 << ASIZE));
    assign awfull = (w_ptr_diff_synced == ((1 << ASIZE) - 1));

    // Calculate rempty and arempty
    wire [ASIZE:0] r_ptr_diff;
    wire [ASIZE:0] r_ptr_diff_synced;
    assign r_ptr_diff = w_gray_count_synced - r_bin_count;
    sync_gray_counter r_ptr_diff_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .gray_in(r_ptr_diff),
        .gray_out(r_ptr_diff_synced)
    );

    assign rempty = (r_ptr_diff_synced == 0);
    assign arempty = (r_ptr_diff_synced == 1);

    // First-word fall-through
    reg [DSIZE-1:0] fallthrough_data;
    reg fallthrough_valid;
    wire fallthrough_ready;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            fallthrough_valid <= 1'b0;
        end else if (rempty && winc && !wfull) begin
            fallthrough_data <= wdata;
            fallthrough_valid <= (FALLTHROUGH == "TRUE");
        end else if (rinc && fallthrough_valid) begin
            fallthrough_valid <= 1'b0;
        end
    end

    assign fallthrough_ready = fallthrough_valid && !rempty;
    assign rdata = fallthrough_ready ? fallthrough_data : rdata;

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] gray_count
);

    reg [ASIZE-1:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
        end else if (inc) begin
            gray_reg <= gray_reg + 1;
        end
    end

    assign gray_count = (gray_reg >> 1) ^ gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] bin_out
);

    assign bin_out = gray_to_bin_converter(gray_in);

    function [ASIZE-1:0] gray_to_bin_converter;
        input [ASIZE-1:0] gray;
        integer i;
        begin
            gray_to_bin_converter = gray;
            for (i = ASIZE - 1; i > 0; i = i - 1) begin
                gray_to_bin_converter[i-1] = gray_to_bin_converter[i-1] ^ gray_to_bin_converter[i];
            end
        end
    endfunction

endmodule

module dual_port_ram (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    output wire [DSIZE-1:0] rdata,
    input  wire [ASIZE-1:0] waddr,
    input  wire [ASIZE-1:0] raddr
);

    reg [DSIZE-1:0] mem [0:(1 << ASIZE) - 1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
        end else if (winc) begin
            mem[waddr] <= wdata;
        end
    end

    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else if (rinc) begin
            rdata_reg <= mem[raddr];
        end
    end

    assign rdata = rdata_reg;

endmodule

module sync_gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] gray_out
);

    reg [ASIZE-1:0] sync_reg1;
    reg [ASIZE-1:0] sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= gray_in;
            sync_reg2 <= sync_reg1;
        end
    end

    assign gray_out = sync_reg2;

endmodule
