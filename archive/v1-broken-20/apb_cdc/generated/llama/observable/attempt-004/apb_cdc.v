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
reg [ADDR_WIDTH-1:0] req_addr [LOG_DEPTH-1:0];
reg [DATA_WIDTH-1:0] req_wdata [LOG_DEPTH-1:0];
reg [DATA_WIDTH/8-1:0] req_strb [LOG_DEPTH-1:0];
reg [2:0] req_prot [LOG_DEPTH-1:0];
reg req_write [LOG_DEPTH-1:0];
reg req_valid [LOG_DEPTH-1:0];
reg req_ready [LOG_DEPTH-1:0];

// Response FIFO
reg [DATA_WIDTH-1:0] resp_rdata [LOG_DEPTH-1:0];
reg resp_valid [LOG_DEPTH-1:0];
reg resp_ready [LOG_DEPTH-1:0];
reg resp_slverr [LOG_DEPTH-1:0];

// Request FIFO control
reg req_empty;
reg req_full;
reg req_re;
reg req_we;

// Response FIFO control
reg resp_empty;
reg resp_full;
reg resp_re;
reg resp_we;

// Clock-domain crossing
reg src_psel_sync;
reg src_penable_sync;
reg src_pwrite_sync;
reg [ADDR_WIDTH-1:0] src_paddr_sync;
reg [DATA_WIDTH-1:0] src_pwdata_sync;
reg [DATA_WIDTH/8-1:0] src_pstrb_sync;
reg [2:0] src_pprot_sync;

// Destination APB control
reg dst_psel_reg;
reg dst_penable_reg;
reg dst_pwrite_reg;
reg [ADDR_WIDTH-1:0] dst_paddr_reg;
reg [DATA_WIDTH-1:0] dst_pwdata_reg;
reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
reg [2:0] dst_pprot_reg;

// Source APB control
reg src_pready_reg;
reg [DATA_WIDTH-1:0] src_prdata_reg;
reg src_pslverr_reg;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
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
    if (~dst_preset_ni) begin
        dst_psel_reg <= 1'b0;
        dst_penable_reg <= 1'b0;
        dst_pwrite_reg <= 1'b0;
        dst_paddr_reg <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_reg <= {DATA_WIDTH{1'b0}};
        dst_pstrb_reg <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_reg <= {3{1'b0}};
    end else begin
        dst_psel_reg <= src_psel_sync;
        dst_penable_reg <= src_penable_sync;
        dst_pwrite_reg <= src_pwrite_sync;
        dst_paddr_reg <= src_paddr_sync;
        dst_pwdata_reg <= src_pwdata_sync;
        dst_pstrb_reg <= src_pstrb_sync;
        dst_pprot_reg <= src_pprot_sync;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_pready_reg <= 1'b0;
        src_prdata_reg <= {DATA_WIDTH{1'b0}};
        src_pslverr_reg <= 1'b0;
    end else begin
        src_pready_reg <= dst_pready_i;
        src_prdata_reg <= dst_prdata_i;
        src_pslverr_reg <= dst_pslverr_i;
    end
end

// Request FIFO
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        req_empty <= 1'b1;
        req_full <= 1'b0;
        req_re <= 1'b0;
        req_we <= 1'b0;
        req_valid <= {LOG_DEPTH{1'b0}};
        req_ready <= {LOG_DEPTH{1'b0}};
        req_addr <= {{LOG_DEPTH-1{ADDR_WIDTH{1'b0}}}, {ADDR_WIDTH{1'b0}}};
        req_wdata <= {{LOG_DEPTH-1{DATA_WIDTH{1'b0}}}, {DATA_WIDTH{1'b0}}};
        req_strb <= {{LOG_DEPTH-1{DATA_WIDTH/8{1'b0}}}, {DATA_WIDTH/8{1'b0}}};
        req_prot <= {{LOG_DEPTH-1{3{1'b0}}}, {3{1'b0}}};
        req_write <= {LOG_DEPTH{1'b0}};
    end else begin
        req_empty <= req_empty;
        req_full <= req_full;
        req_re <= req_re;
        req_we <= req_we;
        req_valid <= req_valid;
        req_ready <= req_ready;
        req_addr <= req_addr;
        req_wdata <= req_wdata;
        req_strb <= req_strb;
        req_prot <= req_prot;
        req_write <= req_write;

        if (src_psel_i && src_penable_i) begin
            req_we <= 1'b1;
            req_addr[0] <= src_paddr_i;
            req_wdata[0] <= src_pwdata_i;
            req_strb[0] <= src_pstrb_i;
            req_prot[0] <= src_pprot_i;
            req_write[0] <= src_pwrite_i;
        end else begin
            req_we <= 1'b0;
        end

        if (dst_pready_i && dst_psel_reg) begin
            req_re <= 1'b1;
            req_addr[0] <= {ADDR_WIDTH{1'b0}};
            req_wdata[0] <= {DATA_WIDTH{1'b0}};
            req_strb[0] <= {DATA_WIDTH/8{1'b0}};
            req_prot[0] <= {3{1'b0}};
            req_write[0] <= 1'b0;
        end else begin
            req_re <= 1'b0;
        end
    end
end

// Response FIFO
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        resp_empty <= 1'b1;
        resp_full <= 1'b0;
        resp_re <= 1'b0;
        resp_we <= 1'b0;
        resp_valid <= {LOG_DEPTH{1'b0}};
        resp_ready <= {LOG_DEPTH{1'b0}};
        resp_rdata <= {{LOG_DEPTH-1{DATA_WIDTH{1'b0}}}, {DATA_WIDTH{1'b0}}};
        resp_slverr <= {LOG_DEPTH{1'b0}};
    end else begin
        resp_empty <= resp_empty;
        resp_full <= resp_full;
        resp_re <= resp_re;
        resp_we <= resp_we;
        resp_valid <= resp_valid;
        resp_ready <= resp_ready;
        resp_rdata <= resp_rdata;
        resp_slverr <= resp_slverr;

        if (dst_pready_i && dst_psel_reg) begin
            resp_we <= 1'b1;
            resp_rdata[0] <= dst_prdata_i;
            resp_slverr[0] <= dst_pslverr_i;
        end else begin
            resp_we <= 1'b0;
        end

        if (src_penable_i && src_psel_i) begin
            resp_re <= 1'b1;
            resp_rdata[0] <= {DATA_WIDTH{1'b0}};
            resp_slverr[0] <= 1'b0;
        end else begin
            resp_re <= 1'b0;
        end
    end
end

assign dst_psel_o = dst_psel_reg;
assign dst_penable_o = dst_penable_reg;
assign dst_pwrite_o = dst_pwrite_reg;
assign dst_paddr_o = dst_paddr_reg;
assign dst_pwdata_o = dst_pwdata_reg;
assign dst_pstrb_o = dst_pstrb_reg;
assign dst_pprot_o = dst_pprot_reg;

assign src_pready_o = src_pready_reg;
assign src_prdata_o = src_prdata_reg;
assign src_pslverr_o = src_pslverr_reg;

endmodule
