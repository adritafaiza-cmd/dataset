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

    wire [ASIZE-1:0] w_gray_ptr;
    wire [ASIZE-1:0] r_gray_ptr;
    wire [ASIZE-1:0] w_gray_synced;
    wire [ASIZE-1:0] r_gray_synced;
    wire [ASIZE-1:0] w_bin_ptr;
    wire [ASIZE-1:0] r_bin_ptr;
    wire w_full_flag;
    wire r_empty_flag;
    wire w_almost_full_flag;
    wire r_almost_empty_flag;

    gray_counter w_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_out(w_gray_ptr)
    );

    gray_counter r_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_out(r_gray_ptr)
    );

    sync_register r_gray_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in(r_gray_ptr),
        .data_out(w_gray_synced)
    );

    sync_register w_gray_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in(w_gray_ptr),
        .data_out(r_gray_synced)
    );

    gray_to_bin w_gray_to_bin (
        .gray_in(w_gray_synced),
        .bin_out(w_bin_ptr)
    );

    gray_to_bin r_gray_to_bin (
        .gray_in(r_gray_synced),
        .bin_out(r_bin_ptr)
    );

    dual_port_ram fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .waddr(w_bin_ptr),
        .wdata(wdata),
        .winc(winc),
        .raddr(r_bin_ptr),
        .rinc(rinc),
        .rdata(rdata)
    );

    assign w_full_flag = (w_bin_ptr == {ASIZE{1'b1}});
    assign r_empty_flag = (r_bin_ptr == {ASIZE{1'b0}});
    assign w_almost_full_flag = (w_bin_ptr == ({ASIZE{1'b1}} - 1'b1));
    assign r_almost_empty_flag = (r_bin_ptr == ({ASIZE{1'b0}} + 1'b1));

    assign wfull = w_full_flag;
    assign awfull = w_almost_full_flag;
    assign rempty = r_empty_flag;
    assign arempty = r_almost_empty_flag;

endmodule

module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ASIZE-1:0] gray_out
);

    reg [ASIZE-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= {ASIZE{1'b0}};
        else if (inc)
            counter <= counter + 1;
    end

    assign gray_out = counter ^ (counter >> 1);

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] bin_out
);

    wire [ASIZE-1:0] gray_feedback;

    assign gray_feedback = {1'b0, gray_in[ASIZE-1:1]};
    assign bin_out = gray_in ^ gray_feedback;

endmodule

module sync_register (
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE-1:0] data_in,
    output reg [ASIZE-1:0] data_out
);

    reg [ASIZE-1:0] sync_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {ASIZE{1'b0}};
            data_out <= {ASIZE{1'b0}};
        end else begin
            sync_stage1 <= data_in;
            data_out <= sync_stage1;
        end
    end

endmodule

module dual_port_ram (
    input  wire wclk,
    input  wire wrst_n,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire winc,
    input  wire [ASIZE-1:0] raddr,
    input  wire rinc,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] memory [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < (2**ASIZE); i = i + 1)
                memory[i] <= {DSIZE{1'b0}};
        end else if (winc) begin
            memory[waddr] <= wdata;
        end
    end

    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= {DSIZE{1'b0}};
        else if (rinc)
            rdata_reg <= memory[raddr];
    end

    assign rdata = rdata_reg;

endmodule
