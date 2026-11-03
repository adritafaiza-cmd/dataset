module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals for FIFOs
    wire [DATA_WIDTH + ADDR_WIDTH + 5 - 1:0] fifo_wr_data;
    wire fifo_wr_en;
    wire fifo_full;
    wire [DATA_WIDTH + ADDR_WIDTH + 5 - 1:0] fifo_rd_data;
    wire fifo_rd_en;
    wire fifo_empty;

    wire [DATA_WIDTH + 1 - 1:0] fifo_resp_wr_data;
    wire fifo_resp_wr_en;
    wire fifo_resp_full;
    wire [DATA_WIDTH + 1 - 1:0] fifo_resp_rd_data;
    wire fifo_resp_rd_en;
    wire fifo_resp_empty;

    // Internal state signals
    reg req_accepted;
    reg req_setup_phase;
    reg req_access_phase;
    reg req_complete;
    reg resp_accepted;
    reg src_ready;
    reg dst_ready;
    reg dst_transfer_complete;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;

    // Request FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + ADDR_WIDTH + 5),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .data_wr(fifo_wr_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        .data_rd(fifo_rd_data),
        .rd_en(fifo_rd_en),
        .empty(fifo_empty)
    );

    // Response FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo_inst (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .data_wr(fifo_resp_wr_data),
        .wr_en(fifo_resp_wr_en),
        .full(fifo_resp_full),
        .data_rd(fifo_resp_rd_data),
        .rd_en(fifo_resp_rd_en),
        .empty(fifo_resp_empty)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
            req_accepted <= 1'b0;
            req_setup_phase <= 1'b0;
            req_access_phase <= 1'b0;
            req_complete <= 1'b0;
            src_ready <= 1'b0;
            fifo_wr_en <= 1'b0;
            fifo_resp_rd_en <= 1'b0;
        end else begin
            // Handle request acceptance
            if (!req_accepted && src_psel_i && src_penable_i && !fifo_full) begin
                req_accepted <= 1'b1;
                fifo_wr_en <= 1'b1;
                fifo_wr_data <= {src_pwdata_i, src_pstrb_i, src_pprot_i, src_paddr_i, src_pwrite_i};
            end else begin
                fifo_wr_en <= 1'b0;
            end

            // Handle request setup phase
            if (req_accepted && !req_setup_phase && !fifo_full) begin
                req_setup_phase <= 1'b1;
            end

            // Handle request access phase
            if (req_setup_phase && !req_access_phase && !fifo_full) begin
                req_access_phase <= 1'b1;
            end

            // Handle request completion
            if (req_access_phase && req_complete) begin
                req_accepted <= 1'b0;
                req_setup_phase <= 1'b0;
                req_access_phase <= 1'b0;
                req_complete <= 1'b0;
            end

            // Handle response FIFO read
            if (!fifo_resp_empty && !src_ready) begin
                fifo_resp_rd_en <= 1'b1;
                src_ready <= 1'b1;
                src_prdata_reg <= fifo_resp_rd_data[DATA_WIDTH-1:0];
                src_pslverr_reg <= fifo_resp_rd_data[DATA_WIDTH];
            end else if (src_ready) begin
                fifo_resp_rd_en <= 1'b0;
                src_ready <= 1'b0;
                src_pready_o <= 1'b1;
            end else begin
                src_pready_o <= 1'b0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= 3'b0;
            dst_ready <= 1'b0;
            dst_transfer_complete <= 1'b0;
            fifo_rd_en <= 1'b0;
            fifo_resp_wr_en <= 1'b0;
        end else begin
            // Handle request FIFO read
            if (!fifo_empty && !dst_ready) begin
                fifo_rd_en <= 1'b1;
                dst_ready <= 1'b1;
                dst_pwrite_o <= fifo_rd_data[DATA_WIDTH + ADDR_WIDTH + 5 - 1];
                dst_paddr_o <= fifo_rd_data[DATA_WIDTH + ADDR_WIDTH + 4 -: ADDR_WIDTH];
                dst_pprot_o <= fifo_rd_data[DATA_WIDTH + ADDR_WIDTH + 3 -: 3];
                dst_pstrb_o <= fifo_rd_data[DATA_WIDTH + ADDR_WIDTH - 1 -: DATA_WIDTH/8];
                dst_pwdata_o <= fifo_rd_data[DATA_WIDTH - 1 -: DATA_WIDTH];
            end else if (dst_ready) begin
                fifo_rd_en <= 1'b0;
            end

            // Handle request setup phase
            if (dst_ready && !dst_penable_o && !dst_psel_o) begin
                dst_psel_o <= 1'b1;
            end

            // Handle request access phase
            if (dst_psel_o && !dst_penable_o && dst_pready_i) begin
                dst_penable_o <= 1'b1;
            end

            // Handle request completion
            if (dst_penable_o && dst_pready_i) begin
                dst_psel_o <= 1'b0;
                dst_penable_o <= 1'b0;
                dst_ready <= 1'b0;
                dst_transfer_complete <= 1'b1;
                fifo_resp_wr_en <= 1'b1;
                fifo_resp_wr_data <= {dst_pslverr_i, dst_prdata_i};
            end else if (dst_transfer_complete) begin
                dst_transfer_complete <= 1'b0;
                fifo_resp_wr_en <= 1'b0;
            end
        end
    end

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input                      clk_rd,
    input                      rst_rd,
    input  [DATA_WIDTH-1:0]    data_wr,
    input                      wr_en,
    output                     full,
    output [DATA_WIDTH-1:0]    data_rd,
    input                      rd_en,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write side logic
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            wr_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= data_wr;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end

    // Read side logic
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            rd_ptr_gray_sync <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            wr_ptr_gray_sync <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Full and empty flags
    assign full = (wr_ptr_gray_sync[ADDR_WIDTH] != rd_ptr_gray[ADDR_WIDTH]) && (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr_gray_sync[ADDR_WIDTH] == rd_ptr_gray_sync[ADDR_WIDTH]) && (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);

    // Read data output
    assign data_rd = mem[rd_ptr];

endmodule
