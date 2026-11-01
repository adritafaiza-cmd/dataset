module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Source clock domain
    reg [WIDTH-1:0] src_buf0;
    reg [WIDTH-1:0] src_buf1;
    reg             src_buf0_valid;
    reg             src_buf1_valid;
    reg             src_buf0_ready;
    reg             src_buf1_ready;

    // Destination clock domain
    reg [WIDTH-1:0] dst_buf0;
    reg [WIDTH-1:0] dst_buf1;
    reg             dst_buf0_valid;
    reg             dst_buf1_valid;
    reg             dst_buf0_ready;
    reg             dst_buf1_ready;

    // Synchronizers for src_ready signals (from dst domain to src domain)
    reg [1:0] src_buf0_ready_sync;
    reg [1:0] src_buf1_ready_sync;

    // Synchronizers for dst_ready signals (from src domain to dst domain)
    reg [1:0] dst_buf0_ready_sync;
    reg [1:0] dst_buf1_ready_sync;

    // Synchronizers for src_valid signals (from src domain to dst domain)
    reg [1:0] src_buf0_valid_sync;
    reg [1:0] src_buf1_valid_sync;

    // Synchronizers for dst_valid signals (from dst domain to src domain)
    reg [1:0] dst_buf0_valid_sync;
    reg [1:0] dst_buf1_valid_sync;

    // Synchronizers for data (from src domain to dst domain)
    reg [WIDTH-1:0] src_buf0_data_sync;
    reg [WIDTH-1:0] src_buf1_data_sync;

    // Synchronizers for data (from dst domain to src domain)
    reg [WIDTH-1:0] dst_buf0_data_sync;
    reg [WIDTH-1:0] dst_buf1_data_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_buf0_valid <= 1'b0;
            src_buf1_valid <= 1'b0;
            src_buf0       <= {WIDTH{1'b0}};
            src_buf1       <= {WIDTH{1'b0}};
        end else begin
            // Buffer 0
            if (src_valid_i && src_ready_o && !src_buf0_valid) begin
                src_buf0_valid <= 1'b1;
                src_buf0       <= src_data_i;
            end else if (src_buf0_valid && src_buf0_ready) begin
                src_buf0_valid <= 1'b0;
            end

            // Buffer 1
            if (src_valid_i && src_ready_o && src_buf0_valid && !src_buf1_valid) begin
                src_buf1_valid <= 1'b1;
                src_buf1       <= src_data_i;
            end else if (src_buf1_valid && src_buf1_ready) begin
                src_buf1_valid <= 1'b0;
            end
        end
    end

    // Source ready: can accept if at least one buffer is empty
    assign src_ready_o = !src_buf0_valid || !src_buf1_valid;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_buf0_valid <= 1'b0;
            dst_buf1_valid <= 1'b0;
            dst_buf0       <= {WIDTH{1'b0}};
            dst_buf1       <= {WIDTH{1'b0}};
        end else begin
            // Buffer 0
            if (src_buf0_valid_sync[1] && !dst_buf0_valid) begin
                dst_buf0_valid <= 1'b1;
                dst_buf0       <= src_buf0_data_sync;
            end else if (dst_buf0_valid && dst_ready_i) begin
                dst_buf0_valid <= 1'b0;
            end

            // Buffer 1
            if (src_buf1_valid_sync[1] && !dst_buf1_valid) begin
                dst_buf1_valid <= 1'b1;
                dst_buf1       <= src_buf1_data_sync;
            end else if (dst_buf1_valid && dst_ready_i) begin
                dst_buf1_valid <= 1'b0;
            end
        end
    end

    // Destination valid: output valid if any buffer has data
    assign dst_valid_o = dst_buf0_valid || dst_buf1_valid;

    // Destination data: output from buffer 0 if valid, else buffer 1
    assign dst_data_o = dst_buf0_valid ? dst_buf0 : dst_buf1;

    // Synchronizers for src_ready (dst domain to src domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_buf0_ready_sync <= 2'b00;
            src_buf1_ready_sync <= 2'b00;
        end else begin
            src_buf0_ready_sync <= {src_buf0_ready_sync[0], dst_buf0_ready_sync[1]};
            src_buf1_ready_sync <= {src_buf1_ready_sync[0], dst_buf1_ready_sync[1]};
        end
    end

    assign src_buf0_ready = src_buf0_ready_sync[1];
    assign src_buf1_ready = src_buf1_ready_sync[1];

    // Synchronizers for dst_ready (src domain to dst domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_buf0_ready_sync <= 2'b00;
            dst_buf1_ready_sync <= 2'b00;
        end else begin
            dst_buf0_ready_sync <= {dst_buf0_ready_sync[0], src_buf0_ready_sync[1]};
            dst_buf1_ready_sync <= {dst_buf1_ready_sync[0], src_buf1_ready_sync[1]};
        end
    end

    assign dst_buf0_ready = dst_buf0_ready_sync[1];
    assign dst_buf1_ready = dst_buf1_ready_sync[1];

    // Synchronizers for src_valid (src domain to dst domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_buf0_valid_sync <= 2'b00;
            src_buf1_valid_sync <= 2'b00;
        end else begin
            src_buf0_valid_sync <= {src_buf0_valid_sync[0], src_buf0_valid};
            src_buf1_valid_sync <= {src_buf1_valid_sync[0], src_buf1_valid};
        end
    end

    // Synchronizers for dst_valid (dst domain to src domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_buf0_valid_sync <= 2'b00;
            dst_buf1_valid_sync <= 2'b00;
        end else begin
            dst_buf0_valid_sync <= {dst_buf0_valid_sync[0], dst_buf0_valid};
            dst_buf1_valid_sync <= {dst_buf1_valid_sync[0], dst_buf1_valid};
        end
    end

    // Synchronizers for data (src domain to dst domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_buf0_data_sync <= {WIDTH{1'b0}};
            src_buf1_data_sync <= {WIDTH{1'b0}};
        end else begin
            src_buf0_data_sync <= src_buf0;
            src_buf1_data_sync <= src_buf1;
        end
    end

    // Synchronizers for data (dst domain to src domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_buf0_data_sync <= {WIDTH{1'b0}};
            dst_buf1_data_sync <= {WIDTH{1'b0}};
        end else begin
            dst_buf0_data_sync <= dst_buf0;
            dst_buf1_data_sync <= dst_buf1;
        end
    end

endmodule
