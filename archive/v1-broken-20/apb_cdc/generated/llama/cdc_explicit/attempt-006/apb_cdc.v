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
reg fifo_empty;
reg fifo_full;
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_rvalid;

// Gray-coded handshake signals
reg [1:0] src_handshake;
reg [1:0] dst_handshake;

// Registered signals
reg src_psel_reg;
reg src_penable_reg;
reg src_pwrite_reg;
reg [ADDR_WIDTH-1:0] src_paddr_reg;
reg [DATA_WIDTH-1:0] src_pwdata_reg;
reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
reg [2:0] src_pprot_reg;
reg dst_pready_reg;

// CDC signals
reg [1:0] src_cdc_pulse;
reg [1:0] dst_cdc_pulse;

// Reset logic
reg src_reset;
reg dst_reset;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_reset <= 1'b1;
        src_cdc_pulse <= 2'b00;
        src_handshake <= 2'b00;
        src_psel_reg <= 1'b0;
        src_penable_reg <= 1'b0;
        src_pwrite_reg <= 1'b0;
        src_paddr_reg <= {ADDR_WIDTH{1'b0}};
        src_pwdata_reg <= {DATA_WIDTH{1'b0}};
        src_pstrb_reg <= {DATA_WIDTH/8{1'b0}};
        src_pprot_reg <= 3'b000;
    end else begin
        src_reset <= 1'b0;
        if (src_cdc_pulse == 2'b01) begin
            src_cdc_pulse <= 2'b10;
        end else if (src_cdc_pulse == 2'b10) begin
            src_cdc_pulse <= 2'b00;
        end
        if (src_psel_i && src_penable_i) begin
            src_handshake <= 2'b01;
            src_psel_reg <= src_psel_i;
            src_penable_reg <= src_penable_i;
            src_pwrite_reg <= src_pwrite_i;
            src_paddr_reg <= src_paddr_i;
            src_pwdata_reg <= src_pwdata_i;
            src_pstrb_reg <= src_pstrb_i;
            src_pprot_reg <= src_pprot_i;
        end else if (src_handshake == 2'b01) begin
            src_handshake <= 2'b10;
        end else if (src_handshake == 2'b10) begin
            src_handshake <= 2'b00;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        dst_reset <= 1'b1;
        dst_cdc_pulse <= 2'b00;
        dst_handshake <= 2'b00;
        dst_pready_reg <= 1'b0;
    end else begin
        dst_reset <= 1'b0;
        if (dst_cdc_pulse == 2'b01) begin
            dst_cdc_pulse <= 2'b10;
        end else if (dst_cdc_pulse == 2'b10) begin
            dst_cdc_pulse <= 2'b00;
        end
        if (dst_pready_i) begin
            dst_handshake <= 2'b01;
            dst_pready_reg <= dst_pready_i;
        end else if (dst_handshake == 2'b01) begin
            dst_handshake <= 2'b10;
        end else if (dst_handshake == 2'b10) begin
            dst_handshake <= 2'b00;
        end
    end
end

// FIFO logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        fifo_write <= 1'b0;
        fifo_addr <= {ADDR_WIDTH{1'b0}};
        fifo_wdata <= {DATA_WIDTH{1'b0}};
        fifo_wstrb <= {DATA_WIDTH/8{1'b0}};
        fifo_wprot <= 3'b000;
    end else begin
        if (src_handshake == 2'b01) begin
            fifo_write <= 1'b1;
            fifo_addr <= src_paddr_reg;
            fifo_wdata <= src_pwdata_reg;
            fifo_wstrb <= src_pstrb_reg;
            fifo_wprot <= src_pprot_reg;
        end else if (fifo_write) begin
            fifo_write <= 1'b0;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        fifo_read <= 1'b0;
    end else begin
        if (dst_handshake == 2'b01) begin
            fifo_read <= 1'b1;
        end else if (fifo_read) begin
            fifo_read <= 1'b0;
        end
    end
end

// CDC handshake
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_cdc_pulse <= 2'b00;
    end else begin
        if (src_cdc_pulse == 2'b00) begin
            src_cdc_pulse <= 2'b01;
        end else if (src_cdc_pulse == 2'b01) begin
            src_cdc_pulse <= 2'b10;
        end else if (src_cdc_pulse == 2'b10) begin
            src_cdc_pulse <= 2'b00;
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        dst_cdc_pulse <= 2'b00;
    end else begin
        if (dst_cdc_pulse == 2'b00) begin
            dst_cdc_pulse <= 2'b01;
        end else if (dst_cdc_pulse == 2'b01) begin
            dst_cdc_pulse <= 2'b10;
        end else if (dst_cdc_pulse == 2'b10) begin
            dst_cdc_pulse <= 2'b00;
        end
    end
end

// Output logic
assign src_pready_o = (src_handshake == 2'b10) && (dst_pready_reg);
assign src_prdata_o = dst_prdata_i;
assign src_pslverr_o = dst_pslverr_i;
assign dst_psel_o = (dst_handshake == 2'b01)? 1'b1 : 1'b0;
assign dst_penable_o = (dst_handshake == 2'b01)? 1'b1 : 1'b0;
assign dst_pwrite_o = (dst_handshake == 2'b01)? src_pwrite_reg : 1'b0;
assign dst_paddr_o = (dst_handshake == 2'b01)? fifo_addr : {ADDR_WIDTH{1'b0}};
assign dst_pwdata_o = (dst_handshake == 2'b01)? fifo_wdata : {DATA_WIDTH{1'b0}};
assign dst_pstrb_o = (dst_handshake == 2'b01)? fifo_wstrb : {DATA_WIDTH/8{1'b0}};
assign dst_pprot_o = (dst_handshake == 2'b01)? fifo_wprot : 3'b000;

endmodule
