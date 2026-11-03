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

    // Internal signals
    reg  [ADDR_WIDTH-1:0]    src_addr_reg;
    reg  [DATA_WIDTH-1:0]    src_data_reg;
    reg  [DATA_WIDTH/8-1:0]  src_strb_reg;
    reg  [2:0]               src_prot_reg;
    reg                      src_write_reg;
    reg                      src_ready_reg;
    reg  [DATA_WIDTH-1:0]    dst_data_reg;
    reg                      dst_slverr_reg;

    // FIFO for buffering requests
    reg  [DATA_WIDTH-1:0]    fifo_data [0:2**LOG_DEPTH-1];
    reg  [ADDR_WIDTH-1:0]    fifo_addr [0:2**LOG_DEPTH-1];
    reg  [DATA_WIDTH/8-1:0]  fifo_strb [0:2**LOG_DEPTH-1];
    reg  [2:0]               fifo_prot [0:2**LOG_DEPTH-1];
    reg                      fifo_write [0:2**LOG_DEPTH-1];
    reg                      fifo_read [0:2**LOG_DEPTH-1];
    reg  [LOG_DEPTH-1:0]     fifo_wr_ptr;
    reg  [LOG_DEPTH-1:0]     fifo_rd_ptr;
    reg                      fifo_full;
    reg                      fifo_empty;

    // FIFO control logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
        end else begin
            if (!fifo_full && src_psel_i && src_penable_i) begin
                fifo_data[fifo_wr_ptr] <= src_pwdata_i;
                fifo_addr[fifo_wr_ptr] <= src_paddr_i;
                fifo_strb[fifo_wr_ptr] <= src_pstrb_i;
                fifo_prot[fifo_wr_ptr] <= src_pprot_i;
                fifo_write[fifo_wr_ptr] <= src_pwrite_i;
                fifo_full <= (fifo_wr_ptr == fifo_rd_ptr) && !fifo_empty;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
            end
            if (!fifo_empty && dst_pready_i) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_empty <= (fifo_wr_ptr == fifo_rd_ptr) && !fifo_full;
            end
        end
    end

    // Destination interface logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else begin
            if (!fifo_empty && dst_pready_i) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_pwrite_o <= fifo_write[fifo_rd_ptr];
                dst_paddr_o <= fifo_addr[fifo_rd_ptr];
                dst_pwdata_o <= fifo_data[fifo_rd_ptr];
                dst_pstrb_o <= fifo_strb[fifo_rd_ptr];
                dst_pprot_o <= fifo_prot[fifo_rd_ptr];
                src_ready_reg <= 1;
            end else begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_pwrite_o <= 0;
                dst_paddr_o <= 0;
                dst_pwdata_o <= 0;
                dst_pstrb_o <= 0;
                dst_pprot_o <= 0;
                src_ready_reg <= 0;
            end
        end
    end

    // Source interface logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            src_pready_o <= src_ready_reg;
            src_prdata_o <= dst_prdata_i;
            src_pslverr_o <= dst_pslverr_i;
        end
    end

endmodule
