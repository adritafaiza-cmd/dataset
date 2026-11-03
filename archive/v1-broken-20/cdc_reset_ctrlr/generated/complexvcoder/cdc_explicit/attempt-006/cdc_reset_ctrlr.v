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

    // Internal signals for synchronization
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Output signals
    reg a_clear_out;
    reg a_isolate_out;
    reg b_clear_out;
    reg b_isolate_out;

    // Synchronization blocks
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_blocks
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear (.sync_in(a_clear_i), .clk(a_clk_i), .rst_ni(a_rst_ni), .sync_out(a_clear_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate (.sync_in(a_isolate_i), .clk(a_clk_i), .rst_ni(a_rst_ni), .sync_out(a_isolate_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack (.sync_in(a_clear_ack_i), .clk(a_clk_i), .rst_ni(a_rst_ni), .sync_out(a_clear_ack_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack (.sync_in(a_isolate_ack_i), .clk(a_clk_i), .rst_ni(a_rst_ni), .sync_out(a_isolate_ack_sync[i]));

            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear (.sync_in(b_clear_i), .clk(b_clk_i), .rst_ni(b_rst_ni), .sync_out(b_clear_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate (.sync_in(b_isolate_i), .clk(b_clk_i), .rst_ni(b_rst_ni), .sync_out(b_isolate_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack (.sync_in(b_clear_ack_i), .clk(b_clk_i), .rst_ni(b_rst_ni), .sync_out(b_clear_ack_sync[i]));
            sync_block #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack (.sync_in(b_isolate_ack_i), .clk(b_clk_i), .rst_ni(b_rst_ni), .sync_out(b_isolate_ack_sync[i]));
        end
    endgenerate

    // Clear and Isolate Controller
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_out <= 0;
            a_isolate_out <= 0;
        end else begin
            if (a_clear_sync[SYNC_STAGES-1] || b_clear_sync[SYNC_STAGES-1]) begin
                a_isolate_out <= 1;
                b_isolate_out <= 1;
            end else begin
                if (a_clear_ack_sync[SYNC_STAGES-1] && b_clear_ack_sync[SYNC_STAGES-1]) begin
                    a_clear_out <= 1;
                    b_clear_out <= 1;
                end else begin
                    a_clear_out <= 0;
                    b_clear_out <= 0;
                end
                if (a_clear_out && b_clear_out && a_clear_ack_sync[SYNC_STAGES-1] && b_clear_ack_sync[SYNC_STAGES-1]) begin
                    a_isolate_out <= 0;
                    b_isolate_out <= 0;
                end
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_out <= 0;
            a_isolate_out <= 0;
        end else begin
            if (a_clear_sync[SYNC_STAGES-1] || b_clear_sync[SYNC_STAGES-1]) begin
                a_isolate_out <= 1;
                b_isolate_out <= 1;
            end else begin
                if (a_clear_ack_sync[SYNC_STAGES-1] && b_clear_ack_sync[SYNC_STAGES-1]) begin
                    a_clear_out <= 1;
                    b_clear_out <= 1;
                end else begin
                    a_clear_out <= 0;
                    b_clear_out <= 0;
                end
                if (a_clear_out && b_clear_out && a_clear_ack_sync[SYNC_STAGES-1] && b_clear_ack_sync[SYNC_STAGES-1]) begin
                    a_isolate_out <= 0;
                    b_isolate_out <= 0;
                end
            end
        end
    end

    assign a_clear_o = a_clear_out;
    assign a_isolate_o = a_isolate_out;
    assign b_clear_o = b_clear_out;
    assign b_isolate_o = b_isolate_out;

endmodule

module sync_block #(
    parameter SYNC_STAGES = 2
)(
    input  sync_in,
    input  clk,
    input  rst_ni,
    output sync_out
);
    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= {sync_in, sync_reg[SYNC_STAGES-2:0]};
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
