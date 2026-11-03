module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    wire [LOG_DEPTH:0] gray_counter_src_gray_o;
    wire [WIDTH-1:0] gray_counter_src_data_o;
    wire gray_counter_src_ready_o;
    wire gray_counter_src_clear_pending_o;
    wire [LOG_DEPTH:0] sync_reg_src_gray_i;
    wire [WIDTH-1:0] sync_reg_src_data_i;
    wire [LOG_DEPTH:0] sync_reg_dst_gray_o;
    wire [LOG_DEPTH:0] gray_counter_dst_gray_i;
    wire [WIDTH-1:0] gray_counter_dst_data_o;
    wire gray_counter_dst_valid_o;
    wire gray_counter_dst_ready_i;
    wire gray_counter_dst_clear_pending_o;

    // Gray counter for source side
    gray_counter #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_counter_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_pending_o(gray_counter_src_clear_pending_o),
        .valid_i(src_valid_i),
        .ready_o(gray_counter_src_ready_o),
        .data_i(src_data_i),
        .data_o(gray_counter_src_data_o),
        .gray_o(gray_counter_src_gray_o)
    );

    // Gray counter for destination side
    gray_counter #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_counter_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_pending_o(gray_counter_dst_clear_pending_o),
        .valid_i(gray_counter_dst_valid_o),
        .ready_i(gray_counter_dst_ready_i),
        .data_i(), // Not used
        .data_o(gray_counter_dst_data_o),
        .gray_i(gray_counter_dst_gray_i)
    );

    // Synchronizer for crossing Gray counters
    sync_register #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_gray_i(gray_counter_src_gray_o),
        .src_data_i(gray_counter_src_data_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_gray_o(sync_reg_dst_gray_o),
        .dst_data_o()
    );

    // Connect signals
    assign sync_reg_src_gray_i = gray_counter_src_gray_o;
    assign sync_reg_src_data_i = gray_counter_src_data_o;
    assign gray_counter_dst_gray_i = sync_reg_dst_gray_o;

    // Outputs
    assign src_clear_pending_o = gray_counter_src_clear_pending_o;
    assign src_ready_o = gray_counter_src_ready_o;
    assign dst_clear_pending_o = gray_counter_dst_clear_pending_o;
    assign dst_data_o = gray_counter_dst_data_o;
    assign dst_valid_o = gray_counter_dst_valid_o;
    assign gray_counter_dst_ready_i = dst_ready_i;

endmodule

// Gray counter module
module gray_counter #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output                 clear_pending_o,
    input                  valid_i,
    output                 ready_o,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o,
    output [LOG_DEPTH:0]   gray_o
);

    reg [LOG_DEPTH:0] bin_ptr;
    reg [LOG_DEPTH:0] gray_ptr;
    reg [LOG_DEPTH:0] gray_ptr_sync;
    reg [LOG_DEPTH:0] gray_ptr_next;
    reg clear_pending;

    // Binary to Gray conversion
    assign gray_ptr_next = (bin_ptr >> 1) ^ bin_ptr;

    // Clear pending signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_pending <= 1'b0;
        end else if (clear_i) begin
            clear_pending <= 1'b1;
        end else if (gray_ptr == gray_ptr_sync) begin
            clear_pending <= 1'b0;
        end
    end

    // Gray counter logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= {LOG_DEPTH+1{1'b0}};
            gray_ptr <= {LOG_DEPTH+1{1'b0}};
        end else if (clear_i) begin
            bin_ptr <= {LOG_DEPTH+1{1'b0}};
            gray_ptr <= {LOG_DEPTH+1{1'b0}};
        end else if (valid_i && ready_o) begin
            bin_ptr <= bin_ptr + 1;
            gray_ptr <= gray_ptr_next;
        end
    end

    // Synchronize Gray pointer to destination clock
    sync_register #(
        .WIDTH(1),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(2) // Minimum 2 stages for Gray code synchronization
    ) sync_gray_ptr (
        .src_rst_ni(rst_ni),
        .src_clk_i(clk_i),
        .src_gray_i(gray_ptr),
        .src_data_i(),
        .dst_rst_ni(rst_ni),
        .dst_clk_i(clk_i),
        .dst_gray_o(gray_ptr_sync),
        .dst_data_o()
    );

    // Ready signal
    assign ready_o = (gray_ptr != gray_ptr_sync);

    // Output data
    assign data_o = data_i;
    assign gray_o = gray_ptr;

    // Clear pending output
    assign clear_pending_o = clear_pending;

endmodule

// Synchronizer register module
module sync_register #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [LOG_DEPTH:0]   src_gray_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [LOG_DEPTH:0]   dst_gray_o,
    output [WIDTH-1:0]     dst_data_o
);

    reg [LOG_DEPTH:0] gray_pipe [SYNC_STAGES-1:0];
    reg [WIDTH-1:0] data_pipe [SYNC_STAGES-1:0];

    // Source side synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            gray_pipe[0] <= {LOG_DEPTH+1{1'b0}};
            data_pipe[0] <= {WIDTH{1'b0}};
        end else begin
            gray_pipe[0] <= src_gray_i;
            data_pipe[0] <= src_data_i;
        end
    end

    // Pipeline stages
    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    gray_pipe[i] <= {LOG_DEPTH+1{1'b0}};
                    data_pipe[i] <= {WIDTH{1'b0}};
                end else begin
                    gray_pipe[i] <= gray_pipe[i-1];
                    data_pipe[i] <= data_pipe[i-1];
                end
            end
        end
    endgenerate

    // Destination side synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_o <= {LOG_DEPTH+1{1'b0}};
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            dst_gray_o <= gray_pipe[SYNC_STAGES-1];
            dst_data_o <= data_pipe[SYNC_STAGES-1];
        end
    end

endmodule
