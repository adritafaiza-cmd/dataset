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

    // Internal signals
    wire src_req_valid;
    wire src_req_ready;
    wire dst_req_valid;
    wire dst_req_ready;
    wire dst_resp_valid;
    wire dst_resp_ready;
    wire src_resp_valid;
    wire src_resp_ready;

    // Source side: capture request when src_psel & src_penable & !src_pready
    // We use a simple handshake: source presents request, bridge accepts when ready.
    
    // Source request register
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;
    reg src_req_valid_reg;

    // Destination request register
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_prot_reg;
    reg dst_write_reg;
    reg dst_req_valid_reg;

    // Destination response register
    reg [DATA_WIDTH-1:0] dst_rdata_reg;
    reg dst_slverr_reg;
    reg dst_resp_valid_reg;

    // Source response register
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_slverr_reg;
    reg src_resp_valid_reg;

    // CDC synchronizers for request valid (src -> dst)
    reg [2:0] req_valid_sync;
    wire req_valid_synced = req_valid_sync[2];

    // CDC synchronizers for response valid (dst -> src)
    reg [2:0] resp_valid_sync;
    wire resp_valid_synced = resp_valid_sync[2];

    // Source side logic
    // src_pready_o is high when no request is pending or when response is ready to be consumed
    // Actually, in APB, pready is asserted during the access phase to indicate completion.
    // The bridge should assert src_pready_o when the destination has completed the transfer.
    
    // Let's use a simpler approach:
    // 1. Source presents a request (psel & penable).
    // 2. Bridge captures the request and asserts src_pready_o after the destination completes.
    // 3. For reads, the data is returned via src_prdata_o.
    
    // State machine for source side
    // IDLE: waiting for request
    // WAIT_DST: request sent to destination, waiting for completion
    // RESP: response available, waiting for source to consume (but in APB, pready is asserted in access phase)
    
    // Actually, in APB, the master asserts PSEL and PENABLE. The slave asserts PREADY.
    // When PREADY is asserted, the transfer is complete. For reads, PRDATA is valid when PREADY is asserted.
    
    // So the bridge should:
    // - When src_psel_i & src_penable_i & !src_pready_o: capture the request
    // - Send the request to the destination
    // - When the destination completes (dst_pready_i), assert src_pready_o
    // - For reads, provide src_prdata_o when src_pready_o is asserted
    
    // Let's implement this with a simple handshake.
    
    // Source request valid: when src_psel_i & src_penable_i & !src_pready_o
    assign src_req_valid = src_psel_i & src_penable_i & ~src_pready_o;
    
    // Source request ready: when the bridge is not already processing a request
    assign src_req_ready = ~src_req_valid_reg;
    
    // Capture request on source clock
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= {ADDR_WIDTH{1'b0}};
            src_wdata_reg <= {DATA_WIDTH{1'b0}};
            src_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            src_prot_reg <= 3'b000;
            src_write_reg <= 1'b0;
            src_req_valid_reg <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_slverr_reg <= 1'b0;
            src_resp_valid_reg <= 1'b0;
        end else begin
            // Capture new request
            if (src_req_valid && src_req_ready) begin
                src_addr_reg <= src_paddr_i;
                src_wdata_reg <= src_pwdata_i;
                src_strb_reg <= src_pstrb_i;
                src_prot_reg <= src_pprot_i;
                src_write_reg <= src_pwrite_i;
                src_req_valid_reg <= 1'b1;
                src_resp_valid_reg <= 1'b0;
            end
            
            // Consume response
            if (src_resp_valid_reg && src_psel_i && src_penable_i) begin
                src_resp_valid_reg <= 1'b0;
            end
        end
    end
    
    // src_pready_o is asserted when the response is valid (for reads) or when the write is complete
    // In APB, PREADY is asserted during the access phase. For writes, it means the write is done.
    // For reads, it means the data is valid.
    assign src_pready_o = src_resp_valid_reg;
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_slverr_reg;
    
    // Destination side logic
    // dst_psel_o is asserted when there is a request to send
    assign dst_psel_o = dst_req_valid_reg;
    assign dst_penable_o = dst_req_valid_reg;
    assign dst_pwrite_o = dst_write_reg;
    assign dst_paddr_o = dst_addr_reg;
    assign dst_pwdata_o = dst_wdata_reg;
    assign dst_pstrb_o = dst_strb_reg;
    assign dst_pprot_o = dst_prot_reg;
    
    // Destination request ready: when the destination is not already processing a request
    assign dst_req_ready = ~dst_req_valid_reg;
    
    // Destination response valid: when dst_pready_i is asserted
    assign dst_resp_valid = dst_pready_i & dst_req_valid_reg;
    
    // Destination response ready: when the source is ready to accept the response
    assign dst_resp_ready = ~src_resp_valid_reg;
    
    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_reg <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            dst_prot_reg <= 3'b000;
            dst_write_reg <= 1'b0;
            dst_req_valid_reg <= 1'b0;
            dst_rdata_reg <= {DATA_WIDTH{1'b0}};
            dst_slverr_reg <= 1'b0;
            dst_resp_valid_reg <= 1'b0;
        end else begin
            // Accept request from source (via CDC)
            if (req_valid_synced && dst_req_ready) begin
                dst_addr_reg <= src_addr_reg;
                dst_wdata_reg <= src_wdata_reg;
                dst_strb_reg <= src_strb_reg;
                dst_prot_reg <= src_prot_reg;
                dst_write_reg <= src_write_reg;
                dst_req_valid_reg <= 1'b1;
                dst_resp_valid_reg <= 1'b0;
            end
            
            // Complete transfer when dst_pready_i is asserted
            if (dst_resp_valid) begin
                dst_req_valid_reg <= 1'b0;
                dst_rdata_reg <= dst_prdata_i;
                dst_slverr_reg <= dst_pslverr_i;
                dst_resp_valid_reg <= 1'b1;
            end
        end
    end
    
    // CDC: request valid from src to dst
    // We need to synchronize the request valid signal and the data.
    // Since the data is stable while the request is valid, we can use a simple synchronizer for the valid signal.
    // The data is captured on the dst clock when the synchronized valid is asserted.
    
    // Synchronize req_valid from src to dst
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_valid_sync <= 3'b000;
        end else begin
            req_valid_sync <= {req_valid_sync[1:0], src_req_valid_reg};
        end
    end
    
    // Synchronize resp_valid from dst to src
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_valid_sync <= 3'b000;
        end else begin
            resp_valid_sync <= {resp_valid_sync[1:0], dst_resp_valid_reg};
        end
    end
    
    // When the response valid is synchronized to the src domain, update the source response registers
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            // Already handled above
        end else begin
            if (resp_valid_synced) begin
                src_rdata_reg <= dst_rdata_reg;
                src_slverr_reg <= dst_slverr_reg;
                src_resp_valid_reg <= 1'b1;
            end
        end
    end

endmodule
