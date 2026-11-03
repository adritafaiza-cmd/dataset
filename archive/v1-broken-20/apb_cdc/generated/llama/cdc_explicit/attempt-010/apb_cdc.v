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
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_valid;
reg fifo_ready;

// FIFO control signals
reg fifo_write;
reg fifo_read;

// Source side signals
reg src_pready_int;
reg [DATA_WIDTH-1:0] src_prdata_int;
reg src_pslverr_int;

// Destination side signals
reg dst_psel_int;
reg dst_penable_int;
reg dst_pwrite_int;
reg [ADDR_WIDTH-1:0] dst_paddr_int;
reg [DATA_WIDTH-1:0] dst_pwdata_int;
reg [DATA_WIDTH/8-1:0] dst_pstrb_int;
reg [2:0] dst_pprot_int;

// CDC handshake signals
reg src_cdc_handshake;
reg dst_cdc_handshake;

// Reset signals
reg src_reset;
reg dst_reset;

// Clock domain crossing signals
reg [ADDR_WIDTH-1:0] cdc_addr;
reg [DATA_WIDTH-1:0] cdc_wdata;
reg [DATA_WIDTH/8-1:0] cdc_wstrb;
reg [2:0] cdc_wprot;
reg cdc_valid;
reg cdc_ready;

// Clock domain crossing handshake signals
reg cdc_handshake;

// Source side logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_int <= 1'b0;
        src_prdata_int <= {DATA_WIDTH{1'b0}};
        src_pslverr_int <= 1'b0;
        src_cdc_handshake <= 1'b0;
    end else begin
        if (src_psel_i && src_penable_i) begin
            if (fifo_ready) begin
                fifo_write <= 1'b1;
                fifo_addr <= src_paddr_i;
                fifo_wdata <= src_pwdata_i;
                fifo_wstrb <= src_pstrb_i;
                fifo_wprot <= src_pprot_i;
            end else begin
                src_pready_int <= 1'b0;
            end
        end else begin
            fifo_write <= 1'b0;
        end

        if (src_cdc_handshake) begin
            src_pready_int <= 1'b1;
            src_prdata_int <= fifo_rdata;
            src_pslverr_int <= dst_pslverr_i;
        end else begin
            src_pready_int <= 1'b0;
        end
    end
end

// Destination side logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_int <= 1'b0;
        dst_penable_int <= 1'b0;
        dst_pwrite_int <= 1'b0;
        dst_paddr_int <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_int <= {DATA_WIDTH{1'b0}};
        dst_pstrb_int <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_int <= {3{1'b0}};
        dst_cdc_handshake <= 1'b0;
    end else begin
        if (cdc_valid) begin
            dst_psel_int <= 1'b1;
            dst_penable_int <= 1'b1;
            dst_pwrite_int <= cdc_wprot[0];
            dst_paddr_int <= cdc_addr;
            dst_pwdata_int <= cdc_wdata;
            dst_pstrb_int <= cdc_wstrb;
            dst_pprot_int <= cdc_wprot;
        end else begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
        end

        if (dst_pready_i) begin
            dst_cdc_handshake <= 1'b1;
        end else begin
            dst_cdc_handshake <= 1'b0;
        end
    end
end

// FIFO logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_valid <= 1'b0;
        fifo_ready <= 1'b1;
        fifo_rdata <= {DATA_WIDTH{1'b0}};
    end else begin
        if (fifo_write) begin
            fifo_valid <= 1'b1;
            fifo_ready <= 1'b0;
        end else if (fifo_read) begin
            fifo_valid <= 1'b0;
            fifo_ready <= 1'b1;
        end
    end
end

// Clock domain crossing logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        cdc_valid <= 1'b0;
        cdc_ready <= 1'b1;
        cdc_addr <= {ADDR_WIDTH{1'b0}};
        cdc_wdata <= {DATA_WIDTH{1'b0}};
        cdc_wstrb <= {DATA_WIDTH/8{1'b0}};
        cdc_wprot <= {3{1'b0}};
    end else begin
        if (fifo_valid) begin
            cdc_valid <= 1'b1;
            cdc_ready <= 1'b0;
            cdc_addr <= fifo_addr;
            cdc_wdata <= fifo_wdata;
            cdc_wstrb <= fifo_wstrb;
            cdc_wprot <= fifo_wprot;
        end else if (cdc_handshake) begin
            cdc_valid <= 1'b0;
            cdc_ready <= 1'b1;
        end
    end
end

// CDC handshake logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        cdc_handshake <= 1'b0;
    end else begin
        if (dst_cdc_handshake) begin
            cdc_handshake <= 1'b1;
        end else begin
            cdc_handshake <= 1'b0;
        end
    end
end

// Output logic
assign src_pready_o = src_pready_int;
assign src_prdata_o = src_prdata_int;
assign src_pslverr_o = src_pslverr_int;
assign dst_psel_o = dst_psel_int;
assign dst_penable_o = dst_penable_int;
assign dst_pwrite_o = dst_pwrite_int;
assign dst_paddr_o = dst_paddr_int;
assign dst_pwdata_o = dst_pwdata_int;
assign dst_pstrb_o = dst_pstrb_int;
assign dst_pprot_o = dst_pprot_int;

endmodule
