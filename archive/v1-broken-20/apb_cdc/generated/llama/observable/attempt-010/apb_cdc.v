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
reg [ADDR_WIDTH-1:0] req_addr [LOG_DEPTH:0];
reg [DATA_WIDTH-1:0] req_wdata [LOG_DEPTH:0];
reg [DATA_WIDTH/8-1:0] req_strb [LOG_DEPTH:0];
reg [2:0] req_prot [LOG_DEPTH:0];
reg req_write [LOG_DEPTH:0];
reg req_valid [LOG_DEPTH:0];
reg req_ready [LOG_DEPTH:0];
reg req_empty;
reg req_full;

// Response FIFO
reg [DATA_WIDTH-1:0] resp_rdata [LOG_DEPTH:0];
reg resp_valid [LOG_DEPTH:0];
reg resp_ready [LOG_DEPTH:0];
reg resp_empty;
reg resp_full;

// Request FIFO logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        req_valid[0] <= 1'b0;
        req_addr[0] <= {ADDR_WIDTH{1'b0}};
        req_wdata[0] <= {DATA_WIDTH{1'b0}};
        req_strb[0] <= {DATA_WIDTH/8{1'b0}};
        req_prot[0] <= {3{1'b0}};
        req_write[0] <= 1'b0;
    end else if (src_psel_i && src_penable_i) begin
        req_valid[0] <= 1'b1;
        req_addr[0] <= src_paddr_i;
        req_wdata[0] <= src_pwdata_i;
        req_strb[0] <= src_pstrb_i;
        req_prot[0] <= src_pprot_i;
        req_write[0] <= src_pwrite_i;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        req_ready[0] <= 1'b0;
    end else if (req_valid[0] && req_ready[0]) begin
        req_valid[0] <= 1'b0;
    end else if (req_valid[0] && ~req_ready[0]) begin
        req_ready[0] <= 1'b1;
    end
end

// Request FIFO shift logic
integer i;
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        for (i = 1; i <= LOG_DEPTH; i++) begin
            req_valid[i] <= 1'b0;
            req_addr[i] <= {ADDR_WIDTH{1'b0}};
            req_wdata[i] <= {DATA_WIDTH{1'b0}};
            req_strb[i] <= {DATA_WIDTH/8{1'b0}};
            req_prot[i] <= {3{1'b0}};
            req_write[i] <= 1'b0;
        end
    end else begin
        for (i = LOG_DEPTH; i > 0; i--) begin
            if (req_valid[i-1] && req_ready[i-1]) begin
                req_valid[i] <= req_valid[i-1];
                req_addr[i] <= req_addr[i-1];
                req_wdata[i] <= req_wdata[i-1];
                req_strb[i] <= req_strb[i-1];
                req_prot[i] <= req_prot[i-1];
                req_write[i] <= req_write[i-1];
            end else begin
                req_valid[i] <= 1'b0;
                req_addr[i] <= {ADDR_WIDTH{1'b0}};
                req_wdata[i] <= {DATA_WIDTH{1'b0}};
                req_strb[i] <= {DATA_WIDTH/8{1'b0}};
                req_prot[i] <= {3{1'b0}};
                req_write[i] <= 1'b0;
            end
        end
    end
end

// Request FIFO empty and full logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        req_empty <= 1'b1;
        req_full <= 1'b0;
    end else if (req_valid[LOG_DEPTH] && ~req_ready[LOG_DEPTH]) begin
        req_full <= 1'b1;
    end else if (~req_valid[LOG_DEPTH] && req_ready[LOG_DEPTH]) begin
        req_full <= 1'b0;
    end else if (req_valid[0] && ~req_ready[0]) begin
        req_empty <= 1'b0;
    end else if (~req_valid[0] && req_ready[0]) begin
        req_empty <= 1'b1;
    end
end

// Response FIFO logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        resp_valid[0] <= 1'b0;
        resp_rdata[0] <= {DATA_WIDTH{1'b0}};
    end else if (dst_psel_o && dst_penable_o && dst_pready_i) begin
        resp_valid[0] <= 1'b1;
        resp_rdata[0] <= dst_prdata_i;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        resp_ready[0] <= 1'b0;
    end else if (resp_valid[0] && resp_ready[0]) begin
        resp_valid[0] <= 1'b0;
    end else if (resp_valid[0] && ~resp_ready[0]) begin
        resp_ready[0] <= 1'b1;
    end
end

// Response FIFO shift logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        for (i = 1; i <= LOG_DEPTH; i++) begin
            resp_valid[i] <= 1'b0;
            resp_rdata[i] <= {DATA_WIDTH{1'b0}};
        end
    end else begin
        for (i = LOG_DEPTH; i > 0; i--) begin
            if (resp_valid[i-1] && resp_ready[i-1]) begin
                resp_valid[i] <= resp_valid[i-1];
                resp_rdata[i] <= resp_rdata[i-1];
            end else begin
                resp_valid[i] <= 1'b0;
                resp_rdata[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end
end

// Response FIFO empty and full logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        resp_empty <= 1'b1;
        resp_full <= 1'b0;
    end else if (resp_valid[LOG_DEPTH] && ~resp_ready[LOG_DEPTH]) begin
        resp_full <= 1'b1;
    end else if (~resp_valid[LOG_DEPTH] && resp_ready[LOG_DEPTH]) begin
        resp_full <= 1'b0;
    end else if (resp_valid[0] && ~resp_ready[0]) begin
        resp_empty <= 1'b0;
    end else if (~resp_valid[0] && resp_ready[0]) begin
        resp_empty <= 1'b1;
    end
end

// Clock-domain crossing logic
reg src_psel_sync;
reg src_penable_sync;
reg src_pwrite_sync;
reg [ADDR_WIDTH-1:0] src_paddr_sync;
reg [DATA_WIDTH-1:0] src_pwdata_sync;
reg [DATA_WIDTH/8-1:0] src_pstrb_sync;
reg [2:0] src_pprot_sync;

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        src_psel_sync <= 1'b0;
        src_penable_sync <= 1'b0;
        src_pwrite_sync <= 1'b0;
        src_paddr_sync <= {ADDR_WIDTH{1'b0}};
        src_pwdata_sync <= {DATA_WIDTH{1'b0}};
        src_pstrb_sync <= {DATA_WIDTH/8{1'b0}};
        src_pprot_sync <= {3{1'b0}};
    end else if (req_valid[LOG_DEPTH] && ~req_ready[LOG_DEPTH]) begin
        src_psel_sync <= 1'b1;
        src_penable_sync <= 1'b1;
        src_pwrite_sync <= req_write[LOG_DEPTH];
        src_paddr_sync <= req_addr[LOG_DEPTH];
        src_pwdata_sync <= req_wdata[LOG_DEPTH];
        src_pstrb_sync <= req_strb[LOG_DEPTH];
        src_pprot_sync <= req_prot[LOG_DEPTH];
    end else begin
        src_psel_sync <= 1'b0;
        src_penable_sync <= 1'b0;
        src_pwrite_sync <= 1'b0;
        src_paddr_sync <= {ADDR_WIDTH{1'b0}};
        src_pwdata_sync <= {DATA_WIDTH{1'b0}};
        src_pstrb_sync <= {DATA_WIDTH/8{1'b0}};
        src_pprot_sync <= {3{1'b0}};
    end
end

// APB interface logic
assign dst_psel_o = src_psel_sync;
assign dst_penable_o = src_penable_sync;
assign dst_pwrite_o = src_pwrite_sync;
assign dst_paddr_o = src_paddr_sync;
assign dst_pwdata_o = src_pwdata_sync;
assign dst_pstrb_o = src_pstrb_sync;
assign dst_pprot_o = src_pprot_sync;

// Response logic
reg [DATA_WIDTH-1:0] resp_rdata_sync;
reg resp_valid_sync;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        resp_rdata_sync <= {DATA_WIDTH{1'b0}};
        resp_valid_sync <= 1'b0;
    end else if (resp_valid[0] && ~resp_ready[0]) begin
        resp_rdata_sync <= resp_rdata[0];
        resp_valid_sync <= 1'b1;
    end else begin
        resp_rdata_sync <= {DATA_WIDTH{1'b0}};
        resp_valid_sync <= 1'b0;
    end
end

assign src_prdata_o = resp_rdata_sync;
assign src_pslverr_o = dst_pslverr_i;
assign src_pready_o = resp_valid_sync;

endmodule
