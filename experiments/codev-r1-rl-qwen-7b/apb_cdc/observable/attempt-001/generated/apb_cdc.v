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

    // Source domain registers
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [DATA_WIDTH-1:0] src_wdata;
    reg [DATA_WIDTH/8-1:0] src_strb;
    reg src_write;
    reg src_psel;
    reg src_penable;
    reg src_req;
    reg src_ack_sync1, src_ack_sync2;

    // Destination domain registers
    reg dst_req_sync1, dst_req_sync2;
    reg dst_ack;

    // Synchronize src_req to destination domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_sync1 <= 0;
            dst_req_sync2 <= 0;
        end else begin
            dst_req_sync1 <= src_req;
            dst_req_sync2 <= dst_req_sync1;
        end
    end

    // Destination domain logic
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pwrite_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_ack <= 0;
        end else begin
            if (dst_req_sync2) begin
                if (!dst_psel_reg) begin
                    dst_psel_reg <= 1;
                    dst_penable_reg <= 0;
                    dst_paddr_reg <= src_addr;
                    dst_pwdata_reg <= src_wdata;
                    dst_pstrb_reg <= src_strb;
                    dst_pwrite_reg <= src_write;
                    dst_pprot_reg <= src_pprot_i;
                end else if (dst_penable_reg && dst_pready_i) begin
                    dst_psel_reg <= 0;
                    dst_penable_reg <= 0;
                    dst_ack <= 1;
                end else begin
                    dst_penable_reg <= 1;
                end
            end else begin
                dst_psel_reg <= 0;
                dst_penable_reg <= 0;
                dst_ack <= 0;
            end
        end
    end

    // Synchronize dst_ack back to source domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_ack_sync1 <= 0;
            src_ack_sync2 <= 0;
        end else begin
            src_ack_sync1 <= dst_ack;
            src_ack_sync2 <= src_ack_sync1;
        end
    end

    // Source domain state machine
    reg state;
    localparam IDLE = 0;
    localparam WAIT_ACK = 1;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            state <= IDLE;
            src_req <= 0;
            src_pready_o <= 1;
            src_addr <= 0;
            src_wdata <= 0;
            src_strb <= 0;
            src_write <= 0;
            src_psel <= 0;
            src_penable <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (src_psel_i && src_penable_i && src_pready_o) begin
                        src_addr <= src_paddr_i;
                        src_wdata <= src_pwdata_i;
                        src_strb <= src_pstrb_i;
                        src_write <= src_pwrite_i;
                        src_psel <= src_psel_i;
                        src_penable <= src_penable_i;
                        src_req <= 1;
                        state <= WAIT_ACK;
                        src_pready_o <= 0;
                    end
                end
                WAIT_ACK: begin
                    if (src_ack_sync2) begin
                        src_req <= 0;
                        state <= IDLE;
                        src_pready_o <= 1;
                    end
                end
            endcase
        end
    end

    // Assign destination outputs
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;

    // Assign response back to source
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

endmodule
