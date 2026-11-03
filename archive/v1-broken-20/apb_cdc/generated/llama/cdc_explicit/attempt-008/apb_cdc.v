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

// FIFO signals
reg [ADDR_WIDTH-1:0] fifo_addr;
reg [DATA_WIDTH-1:0] fifo_wdata;
reg [DATA_WIDTH/8-1:0] fifo_wstrb;
reg [2:0] fifo_wprot;
reg fifo_write;
reg fifo_read;
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_empty;
reg fifo_full;

// Gray-coded handshake signals
reg [LOG_DEPTH:0] src_gray;
reg [LOG_DEPTH:0] dst_gray;

// Registered signals
reg src_psel_r;
reg src_penable_r;
reg src_pwrite_r;
reg [ADDR_WIDTH-1:0] src_paddr_r;
reg [DATA_WIDTH-1:0] src_pwdata_r;
reg [DATA_WIDTH/8-1:0] src_pstrb_r;
reg [2:0] src_pprot_r;
reg dst_pready_r;
reg [DATA_WIDTH-1:0] dst_prdata_r;
reg dst_pslverr_r;

// Output signals
reg src_pready_o_r;
reg [DATA_WIDTH-1:0] src_prdata_o_r;
reg src_pslverr_o_r;
reg dst_psel_o_r;
reg dst_penable_o_r;
reg dst_pwrite_o_r;
reg [ADDR_WIDTH-1:0] dst_paddr_o_r;
reg [DATA_WIDTH-1:0] dst_pwdata_o_r;
reg [DATA_WIDTH/8-1:0] dst_pstrb_o_r;
reg [2:0] dst_pprot_o_r;

// FIFO implementation
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_addr <= '0;
        fifo_wdata <= '0;
        fifo_wstrb <= '0;
        fifo_wprot <= '0;
        fifo_write <= 1'b0;
        fifo_read <= 1'b0;
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
    end else begin
        if (fifo_write) begin
            fifo_addr <= src_paddr_i;
            fifo_wdata <= src_pwdata_i;
            fifo_wstrb <= src_pstrb_i;
            fifo_wprot <= src_pprot_i;
            fifo_empty <= 1'b0;
            if (fifo_full) begin
                fifo_full <= 1'b0;
            end
        end
        if (fifo_read) begin
            fifo_empty <= 1'b1;
            if (fifo_empty) begin
                fifo_empty <= 1'b0;
            end
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        fifo_rdata <= '0;
    end else begin
        if (!fifo_empty) begin
            fifo_rdata <= fifo_wdata;
        end
    end
end

// Gray-coded handshake implementation
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_gray <= '0;
    end else begin
        src_gray <= {src_gray[LOG_DEPTH-1:0], src_psel_i};
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_gray <= '0;
    end else begin
        dst_gray <= {dst_gray[LOG_DEPTH-1:0], dst_pready_i};
    end
end

// Registered signals implementation
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_psel_r <= 1'b0;
        src_penable_r <= 1'b0;
        src_pwrite_r <= 1'b0;
        src_paddr_r <= '0;
        src_pwdata_r <= '0;
        src_pstrb_r <= '0;
        src_pprot_r <= '0;
    end else begin
        src_psel_r <= src_psel_i;
        src_penable_r <= src_penable_i;
        src_pwrite_r <= src_pwrite_i;
        src_paddr_r <= src_paddr_i;
        src_pwdata_r <= src_pwdata_i;
        src_pstrb_r <= src_pstrb_i;
        src_pprot_r <= src_pprot_i;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_pready_r <= 1'b0;
        dst_prdata_r <= '0;
        dst_pslverr_r <= 1'b0;
    end else begin
        dst_pready_r <= dst_pready_i;
        dst_prdata_r <= dst_prdata_i;
        dst_pslverr_r <= dst_pslverr_i;
    end
end

// Output signals implementation
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_o_r <= 1'b0;
        src_prdata_o_r <= '0;
        src_pslverr_o_r <= 1'b0;
    end else begin
        if (fifo_empty) begin
            src_pready_o_r <= 1'b0;
        end else begin
            src_pready_o_r <= 1'b1;
            src_prdata_o_r <= fifo_rdata;
            src_pslverr_o_r <= dst_pslverr_r;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o_r <= 1'b0;
        dst_penable_o_r <= 1'b0;
        dst_pwrite_o_r <= 1'b0;
        dst_paddr_o_r <= '0;
        dst_pwdata_o_r <= '0;
        dst_pstrb_o_r <= '0;
        dst_pprot_o_r <= '0;
    end else begin
        if (!fifo_empty) begin
            dst_psel_o_r <= src_psel_r;
            dst_penable_o_r <= src_penable_r;
            dst_pwrite_o_r <= src_pwrite_r;
            dst_paddr_o_r <= src_paddr_r;
            dst_pwdata_o_r <= src_pwdata_r;
            dst_pstrb_o_r <= src_pstrb_r;
            dst_pprot_o_r <= src_pprot_r;
        end else begin
            dst_psel_o_r <= 1'b0;
            dst_penable_o_r <= 1'b0;
            dst_pwrite_o_r <= 1'b0;
            dst_paddr_o_r <= '0;
            dst_pwdata_o_r <= '0;
            dst_pstrb_o_r <= '0;
            dst_pprot_o_r <= '0;
        end
    end
end

assign src_pready_o = src_pready_o_r;
assign src_prdata_o = src_prdata_o_r;
assign src_pslverr_o = src_pslverr_o_r;
assign dst_psel_o = dst_psel_o_r;
assign dst_penable_o = dst_penable_o_r;
assign dst_pwrite_o = dst_pwrite_o_r;
assign dst_paddr_o = dst_paddr_o_r;
assign dst_pwdata_o = dst_pwdata_o_r;
assign dst_pstrb_o = dst_pstrb_o_r;
assign dst_pprot_o = dst_pprot_o_r;

assign fifo_write = src_psel_i && src_penable_i;
assign fifo_read = dst_pready_i &&!fifo_empty;

endmodule
