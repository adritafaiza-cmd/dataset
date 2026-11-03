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
reg [LOG_DEPTH:0] src_greq;
reg [LOG_DEPTH:0] src_gack;
reg [LOG_DEPTH:0] dst_greq;
reg [LOG_DEPTH:0] dst_gack;

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

// State machine
reg [1:0] state;
reg [1:0] next_state;

// Output assignments
assign src_pready_o = (state == 2'b01);
assign src_prdata_o = fifo_rdata;
assign src_pslverr_o = dst_pslverr_r;
assign dst_psel_o = (state == 2'b10);
assign dst_penable_o = (state == 2'b10);
assign dst_pwrite_o = src_pwrite_r;
assign dst_paddr_o = src_paddr_r;
assign dst_pwdata_o = src_pwdata_r;
assign dst_pstrb_o = src_pstrb_r;
assign dst_pprot_o = src_pprot_r;

// FIFO logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
    end else if (fifo_write &&!fifo_read) begin
        fifo_empty <= 1'b0;
        if (fifo_full) begin
            // Do nothing
        end else begin
            fifo_full <= 1'b1;
        end
    end else if (!fifo_write && fifo_read) begin
        fifo_full <= 1'b0;
        if (fifo_empty) begin
            // Do nothing
        end else begin
            fifo_empty <= 1'b1;
        end
    end else begin
        // Do nothing
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_addr <= {ADDR_WIDTH{1'b0}};
        fifo_wdata <= {DATA_WIDTH{1'b0}};
        fifo_wstrb <= {DATA_WIDTH/8{1'b0}};
        fifo_wprot <= {2{1'b0}};
    end else if (fifo_write) begin
        fifo_addr <= src_paddr_r;
        fifo_wdata <= src_pwdata_r;
        fifo_wstrb <= src_pstrb_r;
        fifo_wprot <= src_pprot_r;
    end else begin
        // Do nothing
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        fifo_rdata <= {DATA_WIDTH{1'b0}};
    end else if (fifo_read) begin
        fifo_rdata <= dst_prdata_r;
    end else begin
        // Do nothing
    end
end

// Registered signals
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_psel_r <= 1'b0;
        src_penable_r <= 1'b0;
        src_pwrite_r <= 1'b0;
        src_paddr_r <= {ADDR_WIDTH{1'b0}};
        src_pwdata_r <= {DATA_WIDTH{1'b0}};
        src_pstrb_r <= {DATA_WIDTH/8{1'b0}};
        src_pprot_r <= {2{1'b0}};
    end else if (src_penable_i && src_psel_i) begin
        src_psel_r <= src_psel_i;
        src_penable_r <= src_penable_i;
        src_pwrite_r <= src_pwrite_i;
        src_paddr_r <= src_paddr_i;
        src_pwdata_r <= src_pwdata_i;
        src_pstrb_r <= src_pstrb_i;
        src_pprot_r <= src_pprot_i;
    end else begin
        // Do nothing
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_pready_r <= 1'b0;
        dst_prdata_r <= {DATA_WIDTH{1'b0}};
        dst_pslverr_r <= 1'b0;
    end else if (dst_pready_i) begin
        dst_pready_r <= dst_pready_i;
        dst_prdata_r <= dst_prdata_i;
        dst_pslverr_r <= dst_pslverr_i;
    end else begin
        // Do nothing
    end
end

// Gray-coded handshake logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_greq <= {LOG_DEPTH+1{1'b0}};
        src_gack <= {LOG_DEPTH+1{1'b0}};
    end else begin
        src_greq <= {src_greq[LOG_DEPTH-1:0], src_penable_i && src_psel_i};
        src_gack <= {src_gack[LOG_DEPTH-1:0], fifo_read};
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_greq <= {LOG_DEPTH+1{1'b0}};
        dst_gack <= {LOG_DEPTH+1{1'b0}};
    end else begin
        dst_greq <= {dst_greq[LOG_DEPTH-1:0], fifo_write};
        dst_gack <= {dst_gack[LOG_DEPTH-1:0], dst_pready_i};
    end
end

// State machine
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        state <= 2'b00;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        2'b00: begin
            if (src_penable_i && src_psel_i) begin
                next_state <= 2'b01;
            end else begin
                next_state <= 2'b00;
            end
        end
        2'b01: begin
            if (dst_pready_i) begin
                next_state <= 2'b10;
            end else begin
                next_state <= 2'b01;
            end
        end
        2'b10: begin
            if (fifo_read) begin
                next_state <= 2'b00;
            end else begin
                next_state <= 2'b10;
            end
        end
        default: begin
            next_state <= 2'b00;
        end
    endcase
end

// FIFO control
assign fifo_write = (state == 2'b01) && (src_penable_i && src_psel_i);
assign fifo_read = (state == 2'b10) && dst_pready_i;

endmodule
