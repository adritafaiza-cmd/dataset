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
    input  [(DATA_WIDTH/8)-1:0] src_pstrb_i,
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
    output [(DATA_WIDTH/8)-1:0] dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // FIFO signals
    reg fifo_full;
    reg fifo_empty;
    reg [ADDR_WIDTH-1:0] fifo_addr;
    reg [DATA_WIDTH-1:0] fifo_data;
    reg [(DATA_WIDTH/8)-1:0] fifo_strb;
    reg [2:0] fifo_prot;
    reg fifo_write;

    // Source domain signals
    reg dst_done_sync;

    // Destination domain signals
    reg dst_busy;
    reg dst_done;

    // Source domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            if (src_pready_o) begin
                fifo_addr <= src_paddr_i;
                fifo_data <= src_pwdata_i;
                fifo_strb <= src_pstrb_i;
                fifo_prot <= src_pprot_i;
                fifo_write <= src_pwrite_i;
                fifo_full <= 1;
                fifo_empty <= 0;
            end else if (dst_done_sync) begin
                fifo_full <= 0;
                fifo_empty <= 1;
            end
        end
    end

    // Synchronize dst_done to source domain
    always @(posedge src_pclk_i) begin
        dst_done_sync <= dst_done;
    end

    // Source ready is based on FIFO not full
    assign src_pready_o = ~fifo_full;

    // Return read data and error
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_busy <= 0;
            dst_done <= 0;
        end else begin
            dst_done <= 0;
            if (dst_busy) begin
                if (dst_penable_o) begin
                    if (dst_pready_i) begin
                        dst_psel_o <= 0;
                        dst_penable_o <= 0;
                        dst_busy <= 0;
                        dst_done <= 1;
                    end else begin
                        dst_penable_o <= 1;
                    end
                end else begin
                    dst_penable_o <= 1;
                end
            end else begin
                if (~fifo_empty) begin
                    dst_paddr_o <= fifo_addr;
                    dst_pwdata_o <= fifo_data;
                    dst_pstrb_o <= fifo_strb;
                    dst_pprot_o <= fifo_prot;
                    dst_pwrite_o <= fifo_write;

                    dst_psel_o <= 1;
                    dst_penable_o <= 0;
                    dst_busy <= 1;
                end
            end
        end
    end

endmodule
