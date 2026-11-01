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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH;

    // Source side state
    reg src_idle;
    reg src_setup;
    reg src_access;
    reg src_done;

    // Destination side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg dst_done;

    // FIFO for request data
    reg [DATA_WIDTH-1:0] req_fifo_data [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] req_fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_fifo_strb [0:DEPTH-1];
    reg [2:0] req_fifo_prot [0:DEPTH-1];
    reg req_fifo_write [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] req_fifo_wptr;
    reg [PTR_WIDTH-1:0] req_fifo_rptr;
    reg req_fifo_valid;

    // FIFO for response data
    reg [DATA_WIDTH-1:0] rsp_fifo_data [0:DEPTH-1];
    reg rsp_fifo_err [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] rsp_fifo_wptr;
    reg [PTR_WIDTH-1:0] rsp_fifo_rptr;
    reg rsp_fifo_valid;

    // CDC synchronizers
    reg [1:0] req_valid_sync;
    reg [1:0] rsp_valid_sync;
    reg [1:0] src_done_sync;
    reg [1:0] dst_done_sync;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_setup <= 1'b0;
            src_access <= 1'b0;
            src_done <= 1'b0;
            req_fifo_wptr <= {PTR_WIDTH{1'b0}};
            req_fifo_valid <= 1'b0;
            rsp_fifo_rptr <= {PTR_WIDTH{1'b0}};
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end else begin
            case (src_idle)
                1'b1: begin
                    src_idle <= 1'b0;
                    src_setup <= 1'b1;
                    src_pready_o <= 1'b0;
                    if (src_psel_i) begin
                        req_fifo_data[req_fifo_wptr] <= src_pwdata_i;
                        req_fifo_addr[req_fifo_wptr] <= src_paddr_i;
                        req_fifo_strb[req_fifo_wptr] <= src_pstrb_i;
                        req_fifo_prot[req_fifo_wptr] <= src_pprot_i;
                        req_fifo_write[req_fifo_wptr] <= src_pwrite_i;
                        req_fifo_wptr <= req_fifo_wptr + 1'b1;
                        req_fifo_valid <= 1'b1;
                    end
                end
                1'b0: begin
                    case (src_setup)
                        1'b1: begin
                            src_setup <= 1'b0;
                            src_access <= 1'b1;
                        end
                        1'b0: begin
                            case (src_access)
                                1'b1: begin
                                    if (rsp_fifo_valid) begin
                                        src_access <= 1'b0;
                                        src_done <= 1'b1;
                                        src_pready_o <= 1'b1;
                                        src_prdata_o <= rsp_fifo_data[rsp_fifo_rptr];
                                        src_pslverr_o <= rsp_fifo_err[rsp_fifo_rptr];
                                        rsp_fifo_rptr <= rsp_fifo_rptr + 1'b1;
                                        rsp_fifo_valid <= 1'b0;
                                    end
                                end
                                1'b0: begin
                                    case (src_done)
                                        1'b1: begin
                                            src_done <= 1'b0;
                                            src_idle <= 1'b1;
                                            src_pready_o <= 1'b0;
                                        end
                                        1'b0: begin
                                        end
                                    endcase
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_done <= 1'b0;
            req_fifo_rptr <= {PTR_WIDTH{1'b0}};
            rsp_fifo_wptr <= {PTR_WIDTH{1'b0}};
            rsp_fifo_valid <= 1'b0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= 3'b0;
        end else begin
            case (dst_idle)
                1'b1: begin
                    if (req_fifo_valid) begin
                        dst_idle <= 1'b0;
                        dst_setup <= 1'b1;
                        dst_psel_o <= 1'b1;
                        dst_penable_o <= 1'b0;
                        dst_pwrite_o <= req_fifo_write[req_fifo_rptr];
                        dst_paddr_o <= req_fifo_addr[req_fifo_rptr];
                        dst_pwdata_o <= req_fifo_data[req_fifo_rptr];
                        dst_pstrb_o <= req_fifo_strb[req_fifo_rptr];
                        dst_pprot_o <= req_fifo_prot[req_fifo_rptr];
                    end
                end
                1'b0: begin
                    case (dst_setup)
                        1'b1: begin
                            dst_setup <= 1'b0;
                            dst_access <= 1'b1;
                            dst_penable_o <= 1'b1;
                        end
                        1'b0: begin
                            case (dst_access)
                                1'b1: begin
                                    if (dst_pready_i) begin
                                        dst_access <= 1'b0;
                                        dst_done <= 1'b1;
                                        rsp_fifo_data[rsp_fifo_wptr] <= dst_prdata_i;
                                        rsp_fifo_err[rsp_fifo_wptr] <= dst_pslverr_i;
                                        rsp_fifo_wptr <= rsp_fifo_wptr + 1'b1;
                                        rsp_fifo_valid <= 1'b1;
                                    end
                                end
                                1'b0: begin
                                    case (dst_done)
                                        1'b1: begin
                                            dst_done <= 1'b0;
                                            dst_idle <= 1'b1;
                                            dst_psel_o <= 1'b0;
                                            dst_penable_o <= 1'b0;
                                        end
                                        1'b0: begin
                                        end
                                    endcase
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
    end

    // Synchronizers
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_valid_sync <= 2'b00;
            rsp_valid_sync <= 2'b00;
            src_done_sync <= 2'b00;
        end else begin
            req_valid_sync <= {req_valid_sync[0], req_fifo_valid};
            rsp_valid_sync <= {rsp_valid_sync[0], rsp_fifo_valid};
            src_done_sync <= {src_done_sync[0], src_done};
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_done_sync <= 2'b00;
        end else begin
            dst_done_sync <= {dst_done_sync[0], dst_done};
        end
    end

endmodule
