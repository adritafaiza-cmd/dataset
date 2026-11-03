module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals
    reg a_isolate_reg;
    reg b_isolate_reg;
    reg a_clear_reg;
    reg b_clear_reg;
    reg a_clear_ack_reg;
    reg b_clear_ack_reg;

    // Synchronization instances
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) a_sync_reset (
        .clk_i(b_clk_i),
        .rst_ni(a_rst_ni),
        .rst_n_o(a_sync_rst_ni)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) b_sync_reset (
        .clk_i(a_clk_i),
        .rst_ni(b_rst_ni),
        .rst_n_o(b_sync_rst_ni)
    );

    // Isolate and clear instances
    isolate_then_clear a_isolate_then_clear (
        .clk_i(a_clk_i),
        .rst_ni(a_sync_rst_ni),
        .clear_i(a_clear_i),
        .clear_o(a_clear_o),
        .clear_ack_i(a_clear_ack_i),
        .isolate_o(a_isolate_o),
        .isolate_ack_i(a_isolate_ack_i)
    );

    isolate_then_clear b_isolate_then_clear (
        .clk_i(b_clk_i),
        .rst_ni(b_sync_rst_ni),
        .clear_i(b_clear_i),
        .clear_o(b_clear_o),
        .clear_ack_i(b_clear_ack_i),
        .isolate_o(b_isolate_o),
        .isolate_ack_i(b_isolate_ack_i)
    );

    // Logic to handle isolation and clear process
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_reg <= 1'b0;
            a_clear_reg <= 1'b0;
        end else begin
            a_isolate_reg <= a_isolate_o;
            a_clear_reg <= a_clear_o;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_reg <= 1'b0;
            b_clear_reg <= 1'b0;
        end else begin
            b_isolate_reg <= b_isolate_o;
            b_clear_reg <= b_clear_o;
        end
    end

    // Wait for acknowledgments before releasing isolation and clear
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_ack_reg <= 1'b0;
        end else begin
            a_clear_ack_reg <= a_clear_ack_i;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_ack_reg <= 1'b0;
        end else begin
            b_clear_ack_reg <= b_clear_ack_i;
        end
    end

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    output rst_n_o
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_STAGES{1'b1}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b0};
        end
    end

    assign rst_n_o = sync_reg[SYNC_STAGES-1];

endmodule

module isolate_then_clear (
    input  clk_i,
    input  rst_ni,
    input  clear_i,
    output clear_o,
    input  clear_ack_i,
    output isolate_o,
    input  isolate_ack_i
);

    reg clear_reg;
    reg isolate_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_reg <= 1'b0;
            isolate_reg <= 1'b0;
        end else begin
            clear_reg <= clear_i;
            isolate_reg <= isolate_o;
        end
    end

    assign clear_o = clear_reg & isolate_reg;
    assign isolate_o = clear_reg & clear_ack_i;

endmodule
