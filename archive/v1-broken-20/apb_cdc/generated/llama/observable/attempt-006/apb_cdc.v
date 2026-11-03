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

reg [ADDR_WIDTH-1:0] src_paddr_r;
reg [DATA_WIDTH-1:0] src_pwdata_r;
reg [DATA_WIDTH/8-1:0] src_pstrb_r;
reg [2:0] src_pprot_r;
reg src_pwrite_r;
reg src_penable_r;
reg src_psel_r;

reg [ADDR_WIDTH-1:0] dst_paddr_r;
reg [DATA_WIDTH-1:0] dst_pwdata_r;
reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
reg [2:0] dst_pprot_r;
reg dst_pwrite_r;
reg dst_penable_r;
reg dst_psel_r;

reg src_pready_r;
reg [DATA_WIDTH-1:0] src_prdata_r;
reg src_pslverr_r;

reg dst_pready_r;
reg [DATA_WIDTH-1:0] dst_prdata_r;
reg dst_pslverr_r;

reg [LOG_DEPTH-1:0] src_fifo_wr_ptr;
reg [LOG_DEPTH-1:0] src_fifo_rd_ptr;
reg src_fifo_empty;
reg src_fifo_full;

reg [LOG_DEPTH-1:0] dst_fifo_wr_ptr;
reg [LOG_DEPTH-1:0] dst_fifo_rd_ptr;
reg dst_fifo_empty;
reg dst_fifo_full;

reg [ADDR_WIDTH-1:0] src_fifo_data [LOG_DEPTH];
reg [DATA_WIDTH-1:0] src_fifo_pwdata [LOG_DEPTH];
reg [DATA_WIDTH/8-1:0] src_fifo_pstrb [LOG_DEPTH];
reg [2:0] src_fifo_pprot [LOG_DEPTH];
reg src_fifo_pwrite [LOG_DEPTH];
reg src_fifo_penable [LOG_DEPTH];
reg src_fifo_psel [LOG_DEPTH];

reg [ADDR_WIDTH-1:0] dst_fifo_data [LOG_DEPTH];
reg [DATA_WIDTH-1:0] dst_fifo_pwdata [LOG_DEPTH];
reg [DATA_WIDTH/8-1:0] dst_fifo_pstrb [LOG_DEPTH];
reg [2:0] dst_fifo_pprot [LOG_DEPTH];
reg dst_fifo_pwrite [LOG_DEPTH];
reg dst_fifo_penable [LOG_DEPTH];
reg dst_fifo_psel [LOG_DEPTH];

reg [DATA_WIDTH-1:0] src_fifo_prdata [LOG_DEPTH];
reg src_fifo_pslverr [LOG_DEPTH];

reg [DATA_WIDTH-1:0] dst_fifo_prdata [LOG_DEPTH];
reg dst_fifo_pslverr [LOG_DEPTH];

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_r <= 1'b0;
        src_prdata_r <= {DATA_WIDTH{1'b0}};
        src_pslverr_r <= 1'b0;
        src_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        src_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        src_fifo_empty <= 1'b1;
        src_fifo_full <= 1'b0;
    end else begin
        if (src_penable_i && src_psel_i) begin
            src_pready_r <= 1'b0;
            if (!src_fifo_full) begin
                src_fifo_data[src_fifo_wr_ptr] <= src_paddr_i;
                src_fifo_pwdata[src_fifo_wr_ptr] <= src_pwdata_i;
                src_fifo_pstrb[src_fifo_wr_ptr] <= src_pstrb_i;
                src_fifo_pprot[src_fifo_wr_ptr] <= src_pprot_i;
                src_fifo_pwrite[src_fifo_wr_ptr] <= src_pwrite_i;
                src_fifo_penable[src_fifo_wr_ptr] <= src_penable_i;
                src_fifo_psel[src_fifo_wr_ptr] <= src_psel_i;
                if (src_fifo_wr_ptr == {LOG_DEPTH{1'b1}}) begin
                    src_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
                end else begin
                    src_fifo_wr_ptr <= src_fifo_wr_ptr + 1'b1;
                end
                src_fifo_empty <= 1'b0;
                if (src_fifo_wr_ptr == src_fifo_rd_ptr) begin
                    src_fifo_full <= 1'b1;
                end
            end
        end else if (src_fifo_empty) begin
            src_pready_r <= 1'b1;
        end
        if (src_fifo_empty && src_psel_i) begin
            src_pready_r <= 1'b0;
        end
        if (src_fifo_full && !src_penable_i) begin
            src_fifo_full <= 1'b0;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_o <= {DATA_WIDTH{1'b0}};
        dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_o <= {3{1'b0}};
        dst_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        dst_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        dst_fifo_empty <= 1'b1;
        dst_fifo_full <= 1'b0;
    end else begin
        if (dst_pready_i && dst_penable_r) begin
            dst_penable_o <= 1'b0;
            if (!dst_fifo_empty) begin
                dst_paddr_o <= dst_fifo_data[dst_fifo_rd_ptr];
                dst_pwdata_o <= dst_fifo_pwdata[dst_fifo_rd_ptr];
                dst_pstrb_o <= dst_fifo_pstrb[dst_fifo_rd_ptr];
                dst_pprot_o <= dst_fifo_pprot[dst_fifo_rd_ptr];
                dst_pwrite_o <= dst_fifo_pwrite[dst_fifo_rd_ptr];
                dst_penable_o <= dst_fifo_penable[dst_fifo_rd_ptr];
                dst_psel_o <= dst_fifo_psel[dst_fifo_rd_ptr];
                if (dst_fifo_rd_ptr == {LOG_DEPTH{1'b1}}) begin
                    dst_fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
                end else begin
                    dst_fifo_rd_ptr <= dst_fifo_rd_ptr + 1'b1;
                end
                dst_fifo_empty <= 1'b0;
                if (dst_fifo_rd_ptr == dst_fifo_wr_ptr) begin
                    dst_fifo_full <= 1'b0;
                end
            end
        end else if (dst_fifo_empty) begin
            dst_penable_o <= 1'b0;
        end
        if (dst_fifo_empty && dst_psel_r) begin
            dst_penable_o <= 1'b0;
        end
        if (dst_fifo_full && !dst_penable_r) begin
            dst_fifo_full <= 1'b0;
        end
        if (!dst_fifo_full) begin
            dst_fifo_data[dst_fifo_wr_ptr] <= src_paddr_r;
            dst_fifo_pwdata[dst_fifo_wr_ptr] <= src_pwdata_r;
            dst_fifo_pstrb[dst_fifo_wr_ptr] <= src_pstrb_r;
            dst_fifo_pprot[dst_fifo_wr_ptr] <= src_pprot_r;
            dst_fifo_pwrite[dst_fifo_wr_ptr] <= src_pwrite_r;
            dst_fifo_penable[dst_fifo_wr_ptr] <= src_penable_r;
            dst_fifo_psel[dst_fifo_wr_ptr] <= src_psel_r;
            if (dst_fifo_wr_ptr == {LOG_DEPTH{1'b1}}) begin
                dst_fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
            end else begin
                dst_fifo_wr_ptr <= dst_fifo_wr_ptr + 1'b1;
            end
            dst_fifo_empty <= 1'b0;
            if (dst_fifo_wr_ptr == dst_fifo_rd_ptr) begin
                dst_fifo_full <= 1'b1;
            end
        end
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_paddr_r <= {ADDR_WIDTH{1'b0}};
        src_pwdata_r <= {DATA_WIDTH{1'b0}};
        src_pstrb_r <= {DATA_WIDTH/8{1'b0}};
        src_pprot_r <= {3{1'b0}};
        src_pwrite_r <= 1'b0;
        src_penable_r <= 1'b0;
        src_psel_r <= 1'b0;
    end else begin
        src_paddr_r <= src_paddr_i;
        src_pwdata_r <= src_pwdata_i;
        src_pstrb_r <= src_pstrb_i;
        src_pprot_r <= src_pprot_i;
        src_pwrite_r <= src_pwrite_i;
        src_penable_r <= src_penable_i;
        src_psel_r <= src_psel_i;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_paddr_r <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_r <= {DATA_WIDTH{1'b0}};
        dst_pstrb_r <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_r <= {3{1'b0}};
        dst_pwrite_r <= 1'b0;
        dst_penable_r <= 1'b0;
        dst_psel_r <= 1'b0;
    end else begin
        dst_paddr_r <= dst_paddr_o;
        dst_pwdata_r <= dst_pwdata_o;
        dst_pstrb_r <= dst_pstrb_o;
        dst_pprot_r <= dst_pprot_o;
        dst_pwrite_r <= dst_pwrite_o;
        dst_penable_r <= dst_penable_o;
        dst_psel_r <= dst_psel_o;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_prdata_r <= {DATA_WIDTH{1'b0}};
        src_pslverr_r <= 1'b0;
    end else begin
        if (src_psel_i && src_penable_i) begin
            src_prdata_r <= dst_prdata_i;
            src_pslverr_r <= dst_pslverr_i;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_prdata_r <= {DATA_WIDTH{1'b0}};
        dst_pslverr_r <= 1'b0;
    end else begin
        if (dst_psel_o && dst_penable_o) begin
            dst_prdata_r <= dst_prdata_i;
            dst_pslverr_r <= dst_pslverr_i;
        end
    end
end

assign src_pready_o = src_pready_r;
assign src_prdata_o = src_prdata_r;
assign src_pslverr_o = src_pslverr_r;

endmodule
