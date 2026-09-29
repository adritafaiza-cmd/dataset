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
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [DATA_WIDTH/8-1:0] strb_reg;
    reg write_reg;
    reg [2:0] prot_reg;

    reg state; // 0: IDLE, 1: BUSY
    reg req;

    // Synchronizers for req and ack
    reg dst_req_sync1, dst_req_sync2;
    reg dst_ack;

    // Destination domain ack synchronization
    reg src_ack_sync1, src_ack_sync2;

    // APB signals to destination
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pwrite_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;

    // Source domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            state <= 0;
            req <= 0;
            addr_reg <= 0;
            wdata_reg <= 0;
            strb_reg <= 0;
            write_reg <= 0;
            prot_reg <= 0;
        end else begin
            case (state)
                0: begin // IDLE
                    if (src_psel_i && src_penable_i && src_pready_o) begin
                        // Latch the data
                        addr_reg <= src_paddr_i;
                        wdata_reg <= src_pwdata_i;
                        strb_reg <= src_pstrb_i;
                        write_reg <= src_pwrite_i;
                        prot_reg <= src_pprot_i;
                        req <= 1;
                        state <= 1;
                    end
                end
                1: begin // BUSY
                    if (src_ack_sync2) begin
                        req <= 0;
                        state <= 0;
                    end
                end
            endcase
        end
    end

    // Synchronize req to destination domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_sync1 <= 0;
            dst_req_sync2 <= 0;
        end else begin
            dst_req_sync1 <= req;
            dst_req_sync2 <= dst_req_sync1;
        end
    end

    // Destination domain logic
    reg dst_state; // 0: IDLE, 1: BUSY

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= 0;
            dst_ack <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
        end else begin
            case (dst_state)
                0: begin
                    if (dst_req_sync2) begin
                        // Start APB transfer
                        dst_psel_reg <= 1;
                        dst_penable_reg <= 1;
                        dst_state <= 1;
                    end
                end
                1: begin
                    if (dst_pready_i) begin
                        // Transfer done
                        dst_psel_reg <= 0;
                        dst_penable_reg <= 0;
                        dst_ack <= 1;
                        dst_state <= 0;
                    end
                end
            endcase
        end
    end

    // Synchronize ack back to source domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_ack_sync1 <= 0;
            src_ack_sync2 <= 0;
        end else begin
            src_ack_sync1 <= dst_ack;
            src_ack_sync2 <= src_ack_sync1;
        end
    end

    // Assign outputs to destination
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = write_reg;
    assign dst_paddr_o = addr_reg;
    assign dst_pwdata_o = wdata_reg;
    assign dst_pstrb_o = strb_reg;
    assign dst_pprot_o = prot_reg;

    // Assign pready_o
    assign src_pready_o = (state == 0);

    // Assign response from destination
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

endmodule
