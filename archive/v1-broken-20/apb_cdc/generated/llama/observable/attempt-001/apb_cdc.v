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

// Request FIFO
reg [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3:0] req_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] req_fifo_rd_ptr;
reg [LOG_DEPTH-1:0] req_fifo_wr_ptr;
reg [LOG_DEPTH-1:0] req_fifo_count;
reg req_fifo_empty;
reg req_fifo_full;

// Response FIFO
reg [DATA_WIDTH+1:0] resp_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] resp_fifo_rd_ptr;
reg [LOG_DEPTH-1:0] resp_fifo_wr_ptr;
reg [LOG_DEPTH-1:0] resp_fifo_count;
reg resp_fifo_empty;
reg resp_fifo_full;

// Request signals
reg src_psel_sync;
reg src_penable_sync;
reg src_pwrite_sync;
reg [ADDR_WIDTH-1:0] src_paddr_sync;
reg [DATA_WIDTH-1:0] src_pwdata_sync;
reg [DATA_WIDTH/8-1:0] src_pstrb_sync;
reg [2:0] src_pprot_sync;

// Response signals
reg dst_prdata_sync;
reg dst_pslverr_sync;

// Synchronization logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_psel_sync <= 1'b0;
        src_penable_sync <= 1'b0;
        src_pwrite_sync <= 1'b0;
        src_paddr_sync <= {ADDR_WIDTH{1'b0}};
        src_pwdata_sync <= {DATA_WIDTH{1'b0}};
        src_pstrb_sync <= {DATA_WIDTH/8{1'b0}};
        src_pprot_sync <= {3{1'b0}};
    end else begin
        src_psel_sync <= src_psel_i;
        src_penable_sync <= src_penable_i;
        src_pwrite_sync <= src_pwrite_i;
        src_paddr_sync <= src_paddr_i;
        src_pwdata_sync <= src_pwdata_i;
        src_pstrb_sync <= src_pstrb_i;
        src_pprot_sync <= src_pprot_i;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_prdata_sync <= {DATA_WIDTH{1'b0}};
        dst_pslverr_sync <= 1'b0;
    end else begin
        dst_prdata_sync <= dst_prdata_i;
        dst_pslverr_sync <= dst_pslverr_i;
    end
end

// Request FIFO logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        req_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        req_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        req_fifo_count <= {LOG_DEPTH{1'b0}};
        req_fifo_empty <= 1'b1;
        req_fifo_full <= 1'b0;
    end else begin
        if (src_penable_sync && src_psel_sync) begin
            if (!req_fifo_full) begin
                req_fifo[req_fifo_wr_ptr] <= {src_paddr_sync, src_pwdata_sync, src_pstrb_sync, src_pprot_sync, src_pwrite_sync};
                req_fifo_wr_ptr <= req_fifo_wr_ptr + 1;
                req_fifo_count <= req_fifo_count + 1;
                req_fifo_empty <= 1'b0;
                if (req_fifo_wr_ptr == (2**LOG_DEPTH)-1) begin
                    req_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
                end
                if (req_fifo_count == (2**LOG_DEPTH)-1) begin
                    req_fifo_full <= 1'b1;
                end
            end
        end
        if (dst_pready_i && dst_psel_o) begin
            if (!req_fifo_empty) begin
                req_fifo_rd_ptr <= req_fifo_rd_ptr + 1;
                req_fifo_count <= req_fifo_count - 1;
                req_fifo_full <= 1'b0;
                if (req_fifo_rd_ptr == (2**LOG_DEPTH)-1) begin
                    req_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
                end
                if (req_fifo_count == 0) begin
                    req_fifo_empty <= 1'b1;
                end
            end
        end
    end
end

// Response FIFO logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        resp_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        resp_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        resp_fifo_count <= {LOG_DEPTH{1'b0}};
        resp_fifo_empty <= 1'b1;
        resp_fifo_full <= 1'b0;
    end else begin
        if (dst_pready_i && dst_psel_o) begin
            if (!resp_fifo_full) begin
                resp_fifo[resp_fifo_wr_ptr] <= {dst_prdata_sync, dst_pslverr_sync};
                resp_fifo_wr_ptr <= resp_fifo_wr_ptr + 1;
                resp_fifo_count <= resp_fifo_count + 1;
                resp_fifo_empty <= 1'b0;
                if (resp_fifo_wr_ptr == (2**LOG_DEPTH)-1) begin
                    resp_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
                end
                if (resp_fifo_count == (2**LOG_DEPTH)-1) begin
                    resp_fifo_full <= 1'b1;
                end
            end
        end
        if (src_penable_sync && src_psel_sync) begin
            if (!resp_fifo_empty) begin
                resp_fifo_rd_ptr <= resp_fifo_rd_ptr + 1;
                resp_fifo_count <= resp_fifo_count - 1;
                resp_fifo_full <= 1'b0;
                if (resp_fifo_rd_ptr == (2**LOG_DEPTH)-1) begin
                    resp_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
                end
                if (resp_fifo_count == 0) begin
                    resp_fifo_empty <= 1'b1;
                end
            end
        end
    end
end

// APB signals
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_o <= {DATA_WIDTH{1'b0}};
        dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_o <= {3{1'b0}};
    end else begin
        if (!req_fifo_empty) begin
            dst_psel_o <= 1'b1;
            dst_penable_o <= 1'b1;
            dst_pwrite_o <= req_fifo[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2];
            dst_paddr_o <= req_fifo[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1:DATA_WIDTH+DATA_WIDTH/8+3];
            dst_pwdata_o <= req_fifo[req_fifo_rd_ptr][DATA_WIDTH+DATA_WIDTH/8+2:DATA_WIDTH/8+3];
            dst_pstrb_o <= req_fifo[req_fifo_rd_ptr][DATA_WIDTH/8+2:DATA_WIDTH/8+3];
            dst_pprot_o <= req_fifo[req_fifo_rd_ptr][2:0];
        end else begin
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= {3{1'b0}};
        end
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_o <= 1'b0;
        src_prdata_o <= {DATA_WIDTH{1'b0}};
        src_pslverr_o <= 1'b0;
    end else begin
        if (!resp_fifo_empty) begin
            src_pready_o <= 1'b1;
            src_prdata_o <= resp_fifo[resp_fifo_rd_ptr][DATA_WIDTH:0];
            src_pslverr_o <= resp_fifo[resp_fifo_rd_ptr][DATA_WIDTH];
        end else begin
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end
    end
end

endmodule
