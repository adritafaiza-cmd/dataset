module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Instantiate the 2-deep FIFO
    async_fifo #(
        .WIDTH(WIDTH)
    ) fifo_inst (
        .clk_wr    (src_clk_i),
        .rst_wr_ni (src_rst_ni),
        .wr_en     (src_valid_i),
        .wr_rdy    (src_ready_o),
        .wr_data   (src_data_i),
        .clk_rd    (dst_clk_i),
        .rst_rd_ni (dst_rst_ni),
        .rd_en     (dst_valid_o),
        .rd_rdy    (dst_ready_i),
        .rd_data   (dst_data_o)
    );

endmodule

module async_fifo #(
    parameter WIDTH = 8
)(
    input              clk_wr,
    input              rst_wr_ni,
    input              wr_en,
    output             wr_rdy,
    input  [WIDTH-1:0] wr_data,
    input              clk_rd,
    input              rst_rd_ni,
    input              rd_en,
    output             rd_rdy,
    output [WIDTH-1:0] rd_data
);

    // Internal signals
    reg [WIDTH-1:0] mem [0:1];
    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;
    reg       full;
    reg       empty;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr <= 2'b00;
            full   <= 1'b0;
        end else begin
            if (wr_en && !full) begin
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == 2'b10) begin
                    full <= 1'b1;
                end
            end else if (rd_en && full) begin
                full <= 1'b0;
            end
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr <= 2'b00;
            empty  <= 1'b1;
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == 2'b10) begin
                    empty <= 1'b1;
                end
            end else if (wr_en && empty) begin
                empty <= 1'b0;
            end
        end
    end

    // Write data to memory
    always @(posedge clk_wr) begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
        end
    end

    // Read data from memory
    always @(posedge clk_rd) begin
        rd_data <= mem[rd_ptr];
    end

    // Ready signals
    assign wr_rdy = ~full;
    assign rd_rdy = ~empty;

endmodule
