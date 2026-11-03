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

    wire [ASIZE-1:0] w_gray;
    wire [ASIZE-1:0] r_gray;
    wire [ASIZE-1:0] w_gray_synced;
    wire [ASIZE-1:0] r_gray_synced;
    wire [ASIZE-1:0] w_ptr_bin;
    wire [ASIZE-1:0] r_ptr_bin;
    wire [ASIZE-1:0] w_ptr_synced_bin;
    wire [ASIZE-1:0] r_ptr_synced_bin;
    wire             w_full_raw;
    wire             r_empty_raw;
    wire             w_almost_full_raw;
    wire             r_almost_empty_raw;
    wire             w_full_synced;
    wire             r_empty_synced;

    gray_counter w_gray_counter (
        .clk  (wclk),
        .rst_n(wrst_n),
        .inc  (winc & ~wfull),
        .gray (w_gray)
    );

    gray_counter r_gray_counter (
        .clk  (rclk),
        .rst_n(rrst_n),
        .inc  (rinc & ~rempty),
        .gray (r_gray)
    );

    sync_gray w_gray_sync (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .gray_in(w_gray),
        .gray_out(w_gray_synced)
    );

    sync_gray r_gray_sync (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .gray_in(r_gray),
        .gray_out(r_gray_synced)
    );

    memory mem (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .wen    (winc & ~wfull),
        .waddr  (w_gray),
        .wdata  (wdata),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .ren    (rinc & ~rempty),
        .raddr  (r_gray),
        .rdata  (rdata)
    );

    // Binary conversion and pointer logic
    binary_converter w_gray_to_bin (
        .gray (w_gray),
        .bin  (w_ptr_bin)
    );

    binary_converter r_gray_to_bin (
        .gray (r_gray),
        .bin  (r_ptr_bin)
    );

    binary_converter w_gray_synced_to_bin (
        .gray (w_gray_synced),
        .bin  (w_ptr_synced_bin)
    );

    binary_converter r_gray_synced_to_bin (
        .gray (r_gray_synced),
        .bin  (r_ptr_synced_bin)
    );

    // Full and empty flags
    assign w_full_raw = (w_ptr_bin == r_ptr_synced_bin);
    assign r_empty_raw = (r_ptr_bin == w_ptr_synced_bin);

    sync_flag w_full_sync (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .flag_in(w_full_raw),
        .flag_out(w_full_synced)
    );

    sync_flag r_empty_sync (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .flag_in(r_empty_raw),
        .flag_out(r_empty_synced)
    );

    // Almost full and almost empty flags
    assign w_almost_full_raw = (w_ptr_bin == {r_ptr_synced_bin[ASIZE-1:1], ~r_ptr_synced_bin[0]});
    assign r_almost_empty_raw = (r_ptr_bin == {w_ptr_synced_bin[ASIZE-1:1], ~w_ptr_synced_bin[0]});

    assign wfull = w_full_synced;
    assign awfull = w_almost_full_raw;
    assign rempty = r_empty_synced;
    assign arempty = r_almost_empty_raw;

    // Fall-through logic
    reg [DSIZE-1:0] fallthrough_data;
    reg fallthrough_valid;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            fallthrough_data <= 0;
            fallthrough_valid <= 0;
        end else begin
            if (rinc & ~rempty) begin
                fallthrough_valid <= 0;
            end else if (fallthrough_valid) begin
                // Do nothing
            end else if (FALLTHROUGH == "TRUE" && ~rempty) begin
                fallthrough_data <= rdata;
                fallthrough_valid <= 1;
            end
        end
    end

    assign rdata = (fallthrough_valid && FALLTHROUGH == "TRUE") ? fallthrough_data : rdata;

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] gray
);

    reg [ASIZE-1:0] bin;
    reg [ASIZE-1:0] bin_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin <= 0;
        end else if (inc) begin
            bin <= bin_next;
        end
    end

    assign bin_next = bin + 1;
    assign gray = bin ^ (bin >> 1);

endmodule

module sync_gray (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] gray_out
);

    reg [ASIZE-1:0] gray_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage1 <= 0;
            gray_out <= 0;
        end else begin
            gray_stage1 <= gray_in;
            gray_out <= gray_stage1;
        end
    end

endmodule

module memory (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             wen,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             ren,
    input  wire [ASIZE-1:0] raddr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] mem_array [0:(1<<ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem_array <= '{default: 0};
        end else if (wen) begin
            mem_array[waddr] <= wdata;
        end
    end

    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else if (ren) begin
            rdata_reg <= mem_array[raddr];
        end
    end

    assign rdata = rdata_reg;

endmodule

module binary_converter (
    input  wire [ASIZE-1:0] gray,
    output wire [ASIZE-1:0] bin
);

    reg [ASIZE-1:0] bin_reg;

    always @(*) begin
        bin_reg[ASIZE-1] = gray[ASIZE-1];
        for (integer i = ASIZE-2; i >= 0; i = i - 1) begin
            bin_reg[i] = bin_reg[i+1] ^ gray[i];
        end
    end

    assign bin = bin_reg;

endmodule

module sync_flag (
    input  wire clk,
    input  wire rst_n,
    input  wire flag_in,
    output wire flag_out
);

    reg flag_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag_stage1 <= 0;
            flag_out <= 0;
        end else begin
            flag_stage1 <= flag_in;
            flag_out <= flag_stage1;
        end
    end

endmodule
