```verilog
module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    localparam DEASSERT_DEPTH = CHAINS;

    // Internal signal to handle polarity inversion if needed
    // If RST_POL is 0 (active low), we treat async_rst_i as active high for logic
    // If RST_POL is 1 (active high), we treat async_rst_i as active high directly
    wire rst_active_high;
    assign rst_active_high = RST_POL ? async_rst_i : ~async_rst_i;

    // Synchronizer chain for the deassertion event
    // We need to detect the transition from Asserted to Deasserted.
    // Since the reset is active-high in our internal logic (rst_active_high),
    // we wait for the signal to go low.
    
    // Stage 1
    reg rst_sync_1;
    always @(posedge clk or posedge rst_active_high) begin
        if (rst_active_high)
            rst_sync_1 <= 1'b1;
        else
            rst_sync_1 <= rst_sync_1;
    end

    // Stage 2
    reg rst_sync_2;
    always @(posedge clk or posedge rst_sync_1) begin
        if (rst_sync_1)
            rst_sync_2 <= 1'b1;
        else
            rst_sync_2 <= rst_sync_2;
    end

    // Stage 3
    reg rst_sync_3;
    always @(posedge clk or posedge rst_sync_2) begin
        if (rst_sync_2)
            rst_sync_3 <= 1'b1;
        else
            rst_sync_3 <= rst_sync_3;
    end

    // Stage 4
    reg rst_sync_4;
    always @(posedge clk or posedge rst_sync_3) begin
        if (rst_sync_3)
            rst_sync_4 <= 1'b1;
        else
            rst_sync_4 <= rst_sync_4;
    end

    // Stage 5
    reg rst_sync_5;
    always @(posedge clk or posedge rst_sync_4) begin
        if (rst_sync_4)
            rst_sync_5 <= 1'b1;
        else
            rst_sync_5 <= rst_sync_5;
    end

    // Stage 6
    reg rst_sync_6;
    always @(posedge clk or posedge rst_sync_5) begin
        if (rst_sync_5)
            rst_sync_6 <= 1'b1;
        else
            rst_sync_6 <= rst_sync_6;
    end

    // Stage 7
    reg rst_sync_7;
    always @(posedge clk or posedge rst_sync_6) begin
        if (rst_sync_6)
            rst_sync_7 <= 1'b1;
        else
            rst_sync_7 <= rst_sync_7;
    end

    // Stage 8
    reg rst_sync_8;
    always @(posedge clk or posedge rst_sync_7) begin
        if (rst_sync_7)
            rst_sync_8 <= 1'b1;
        else
            rst_sync_8 <= rst_sync_8;
    end

    // Stage 9
    reg rst_sync_9;
    always @(posedge clk or posedge rst_sync_8) begin
        if (rst_sync_8)
            rst_sync_9 <= 1'b1;
        else
            rst_sync_9 <= rst_sync_9;
    end

    // Stage 10
    reg rst_sync_10;
    always @(posedge clk or posedge rst_sync_9) begin
        if (rst_sync_9)
            rst_sync_10 <= 1'b1;
        else
            rst_sync_10 <= rst_sync_10;
    end

    // Stage 11
    reg rst_sync_11;
    always @(posedge clk or posedge rst_sync_10) begin
        if (rst_sync_10)
            rst_sync_11 <= 1'b1;
        else
            rst_sync_11 <= rst_sync_11;
    end

    // Stage 12
    reg rst_sync_12;
    always @(posedge clk or posedge rst_sync_11) begin
        if (rst_sync_11)
            rst_sync_12 <= 1'b1;
        else
            rst_sync_12 <= rst_sync_12;
    end

    // Stage 13
    reg rst_sync_13;
    always @(posedge clk or posedge rst_sync_12) begin
        if (rst_sync_12)
            rst_sync_13 <= 1'b1;
        else
            rst_sync_13 <= rst_sync_13;
    end

    // Stage 14
    reg rst_sync_14;
    always @(posedge clk or posedge rst_sync_13) begin
        if (rst_sync_13)
            rst_sync_14 <= 1'b1;
        else
            rst_sync_14 <= rst_sync_14;
    end

    // Stage 15
    reg rst_sync_15;
    always @(posedge clk or posedge rst_sync_14) begin
        if (rst_sync_14)
            rst_sync_15 <= 1'b1;
        else
            rst_sync_15 <= rst_sync_15;
    end

    // Stage 16
    reg rst_sync_16;
    always @(posedge clk or posedge rst_sync_15) begin
        if (rst_sync_15)
            rst_sync_16 <= 1'b1;
        else
            rst_sync_16 <= rst_sync_16;
    end

    // Stage 17
    reg rst_sync_17;
    always @(posedge clk or posedge rst_sync_16) begin
        if (rst_sync_16)
            rst_sync_17 <= 1'b1;
        else
            rst_sync_17 <= rst_sync_17;
    end

    // Stage 18
    reg rst_sync_18;
    always @(posedge clk or posedge rst_sync_17) begin
        if (rst_sync_17)
            rst_sync_18 <= 1'b1;
        else
            rst_sync_18 <= rst_sync_18;
    end

    // Stage 19
    reg rst_sync_19;
    always @(posedge clk or posedge rst_sync_18) begin
        if (rst_sync_18)
            rst_sync_19 <= 1'b1;
        else
            rst_sync_19 <= rst_sync_19;
    end

    // Stage 20
    reg rst_sync_20;
    always @(posedge clk or posedge rst_sync_19) begin
        if (rst_sync_19)
            rst_sync_20 <= 1'b1;
        else
            rst_sync_20 <= rst_sync_20;
    end

    // Stage 21
    reg rst_sync_21;
    always @(posedge clk or posedge rst_sync_20) begin
        if (rst_sync_20)
            rst_sync_21 <= 1'b1;
        else
            rst_sync_21 <= rst_sync_21;
    end

    // Stage 22
    reg rst_sync_22;
    always @(posedge clk or posedge rst_sync_21) begin
        if (rst_sync_21)
            rst_sync_22 <= 1'b1;
        else
            rst_sync_22 <= rst_sync_22;
    end

    // Stage 23
    reg rst_sync_23;
    always @(posedge clk or posedge rst_sync_22) begin
        if (rst_sync_22)
            rst_sync_23 <= 1'b1;
        else
            rst_sync_23 <= rst_sync_23;
    end

    // Stage 24
    reg rst_sync_24;
    always @(posedge clk or posedge rst_sync_23) begin
        if (rst_sync_23)
            rst_sync_24 <= 1'b1;
        else
            rst_sync_24 <= rst_sync_24;
    end

    // Stage 25
    reg rst_sync_25;
    always @(posedge clk or posedge rst_sync_24) begin
        if (rst_sync_24)
            rst_sync_25 <= 1'b1;
        else
            rst_sync_25 <= rst_sync_25;
    end

    // Stage 26
    reg rst_sync_26;
    always @(posedge clk or posedge rst_sync_25) begin
        if (rst_sync_25)
            rst_sync_26 <= 1'b1;
        else
            rst_sync_26 <= rst_sync_26;
    end

    // Stage 27
    reg rst_sync_27;
    always @(posedge clk or posedge rst_sync_26) begin
        if (rst_sync_26)
            rst_sync_27 <= 1'b1;
        else
            rst_sync_27 <= rst_sync_27;
    end

    // Stage 28
    reg rst_sync_28;
    always @(posedge clk or posedge rst_sync_27) begin
        if (rst_sync_27)
            rst_sync_28 <= 1'b1;
        else
            rst_sync_28 <= rst_sync_28;
    end

    // Stage 29
    reg rst_sync_29;
    always @(posedge clk or posedge rst_sync_28) begin
        if (rst_sync_28)
            rst_sync_29 <= 1'b1;
        else
            rst_sync_29 <= rst_sync_29;
    end

    // Stage 30
    reg rst_sync_30;
    always @(posedge clk or posedge rst_sync_29) begin
        if (rst_sync_29)
            rst_sync_30 <= 1'b1;
        else
            rst_sync_30 <= rst_sync_30;
    end

    // Stage 31
    reg rst_sync_31;
    always @(posedge clk or posedge rst_sync_30) begin
        if (rst_sync_30)
            rst_sync_31 <= 1'b1;
        else
            rst_sync_31 <= rst_sync_31;
    end

    // Stage 32
    reg rst_sync_32;
    always @(posedge clk or posedge rst_sync_31) begin
        if (rst_sync_31)
            rst_sync_32 <= 1'b1;
        else
            rst_sync_32 <= rst_sync_32;
    end

    // Stage 33
    reg rst_sync_33;
    always @(posedge clk or posedge rst_sync_32) begin
        if (rst_sync_32)
            rst_sync_33 <= 1'b1;
        else
            rst_sync_33 <= rst_sync_33;
    end

    // Stage 34
    reg rst_sync_34;
    always @(posedge clk or posedge rst_sync_33) begin
        if (rst_sync_33)
            rst_sync_34 <= 1'b1;
        else
            rst_sync_34 <= rst_sync_34;
    end

    // Stage 35
    reg rst_sync_35;
    always @(posedge clk or posedge rst_sync_34) begin
        if (rst_sync_34)
            rst_sync_35 <= 1'b1;
        else
            rst_sync_35 <= rst_sync_35;
    end

    // Stage 36
    reg rst_sync_36;
    always @(posedge clk or posedge rst_sync_35) begin
        if (rst_sync_35)
            rst_sync_36 <= 1'b1;
        else
            rst_sync_36 <= rst_sync_36;
    end

    // Stage 37
    reg rst_sync_37;
    always @(posedge clk or posedge rst_sync_36) begin
        if (rst_sync_36)
            rst_sync_37 <= 1'b1;
        else
            rst_sync_37 <= rst_sync_37;
    end

    // Stage 38
    reg rst_sync_38;
    always @(posedge clk or posedge rst_sync_37) begin
        if (rst_sync_37)
            rst_sync_38 <= 1'b1;
        else
            rst_sync_38 <= rst_sync_38;
    end

    // Stage 39
    reg rst_sync_39;
    always @(posedge clk or posedge rst_sync_38) begin
        if (rst_sync_38)
            rst_sync_39 <= 1'b1;
        else
            rst_sync_39 <= rst_sync_39;
    end

    // Stage 40
    reg rst_sync_40;
    always @(posedge clk or posedge rst_sync_39) begin
        if (rst_sync_39)
            rst_sync_40 <= 1'b1;
        else
            rst_sync_40 <= rst_sync_40;
    end

    // Stage 41
    reg rst_sync_41;
    always @(posedge clk or posedge rst_sync_40) begin
        if (rst_sync_40)
            rst_sync_41 <= 1'b1;
        else
            rst_sync_41 <= rst_sync_41;
    end

    // Stage 42
    reg rst_sync_42;
    always @(posedge clk or posedge rst_sync_41) begin
        if (rst_sync_41)
            rst_sync_42 <= 1'b1;
        else
            rst_sync_42 <= rst_sync_42;
    end

    // Stage 43
    reg rst_sync_43;
    always @(posedge clk or posedge rst_sync_42) begin
        if (rst_sync_42)
            rst_sync_43 <= 1'b1;
        else
            rst_sync_43 <= rst_sync_43;
    end

    // Stage 44
    reg rst_sync_44;
    always @(posedge clk or posedge rst_sync_43) begin
        if (rst_sync_43)
            rst_sync_44 <= 1'b1;
        else
            rst_sync_44 <= rst_sync_44;
    end

    // Stage 45
    reg rst_sync_45;
    always @(posedge clk or posedge rst_sync_44) begin
        if (rst_sync_44)
            rst_sync_45 <= 1'b1;
        else
            rst_sync_45 <= rst_sync_45;
    end

    // Stage 46
    reg rst_sync_46;
    always @(posedge clk or posedge rst_sync_45) begin
        if (rst_sync_45)
            rst_sync_46 <= 1'b1;
        else
            rst_sync_46 <= rst_sync_46;
    end

    // Stage 47
    reg rst_sync_47;
    always @(posedge clk or posedge rst_sync_46) begin
        if (rst_sync_46)
            rst_sync_47 <= 1'b1;
        else
            rst_sync_47 <= rst_sync_47;
    end

    // Stage 48
    reg rst_sync_48;
    always @(posedge clk or posedge rst_sync_47) begin
        if (rst_sync_47)
            rst_sync_48 <= 1'b1;
        else
            rst_sync_48 <= rst_sync_48;
    end

    // Stage 49
    reg rst_sync_49;
    always @(posedge clk or posedge rst_sync_48) begin
        if (rst_sync_48)
            rst_sync_49 <= 1'b1;
        else
            rst_sync_49 <= rst_sync_49;
    end

    // Stage 50
    reg rst_sync_50;
    always @(posedge clk or posedge rst_sync_49) begin
        if (rst_sync_49)
            rst_sync_50 <= 1'b1;
        else
            rst_sync_50 <= rst_sync_50;
    end

    // Stage 51
    reg rst_sync_51;
    always @(posedge clk or posedge rst_sync_50) begin
        if (rst_sync_50)
            rst_sync_51 <= 1'b1;
        else
            rst_sync_51 <= rst_sync_51;
    end

    // Stage 52
    reg rst_sync_52;
    always @(posedge clk or posedge rst_sync_51) begin
        if (rst_sync_51)
            rst_sync_52 <= 1'b1;
        else
            rst_sync_52 <= rst_sync_52;
    end

    // Stage 53
    reg rst_sync_53;
    always @(posedge clk or posedge rst_sync_52) begin
        if (rst_sync_52)
            rst_sync_53 <= 1'b1;
        else
            rst_sync_53 <= rst_sync_53;
    end

    // Stage 54
    reg rst_sync_54;
    always @(posedge clk or posedge rst_sync_53) begin
        if (rst_sync_53)
            rst_sync_54 <= 1'b1;
        else
            rst_sync_54 <= rst_sync_54;
    end

    // Stage 55
    reg rst_sync_55;
    always @(posedge clk or posedge rst_sync_54) begin
        if (rst_sync_54)
            rst_sync_55 <= 1'b1;
        else
            rst_sync_55 <= rst_sync_55;
    end

    // Stage 56
    reg rst_sync_56;
    always @(posedge clk or posedge rst_sync_55) begin
        if (rst_sync_55)
            rst_sync_56 <= 1'b1;
        else
            rst_sync_56 <= rst_sync_56;
    end

    // Stage 57
    reg rst_sync_57;
    always @(posedge clk or posedge rst_sync_56) begin
        if (rst_sync_56)
            rst_sync_57 <= 1'b1;
        else
            rst_sync_57 <= rst_sync_57;
    end

    // Stage 58
    reg rst_sync_58;
    always @(posedge clk or posedge rst_sync_57) begin
        if (rst_sync_57)
            rst_sync_58 <= 1'b1;
        else
            rst_sync_58 <= rst_sync_58;
    end

    // Stage 59
    reg rst_sync_59;
    always @(posedge clk or posedge rst_sync_58) begin
        if (rst_sync_58)
            rst_sync_59 <= 1'b1;
        else
            rst_sync_59 <= rst_sync_59;
    end

    // Stage 60
    reg rst_sync_60;
    always @(posedge clk or posedge rst_sync_59) begin
        if (rst_sync_59)
            rst_sync_60 <= 1'b1;
        else
            rst_sync_60 <= rst_sync_60;
    end

    // Stage 61
    reg rst_sync_61;
    always @(posedge clk or posedge rst_sync_60) begin
        if (rst_sync_60)
            rst_sync_61 <= 1'b1;
        else
            rst_sync_61 <= rst_sync_61;
    end

    // Stage 62
    reg rst_sync_62;
    always @(posedge clk or posedge rst_sync_61) begin
        if (rst_sync_61)
            rst_sync_62 <= 1'b1;
        else
            rst_sync_62 <= rst_sync_62;
    end

    // Stage 63
    reg rst_sync_63;
    always @(posedge clk or posedge rst_sync_62) begin
        if (rst_sync_62)
            rst_sync_63 <= 1'b1;
        else
            rst_sync_63 <= rst_sync_63;
    end

    // Stage 64
    reg rst_sync_64;
    always @(posedge clk or posedge rst_sync_63) begin
        if (rst_sync_63)
            rst_sync_64 <= 1'b1;
        else
            rst_sync_64 <= rst_sync_64;
    end

    // Stage 65
    reg rst_sync_65;
    always @(posedge clk or posedge rst_sync_64) begin
        if (rst_sync_64)
            rst_sync_65 <= 1'b1;
        else
            rst_sync_65 <= rst_sync_65;
    end

    // Stage 66
    reg rst_sync_66;
    always @(posedge clk or posedge rst_sync_65) begin
        if (rst_sync_65)
            rst_sync_66 <= 1'b1;
        else
            rst_sync_66 <= rst_sync_66;
    end

    // Stage 67
    reg rst_sync_67;
    always @(posedge clk or posedge rst_sync_66) begin
        if (rst_sync_66)
            rst_sync_67 <= 1'b1;
        else
            rst_sync_67 <= rst_sync_67;
    end

    // Stage 68
    reg rst_sync_68;
    always @(posedge clk or posedge rst_sync_67) begin
        if (rst_sync_67)
            rst_sync_68 <= 1'b1;
        else
            rst_sync_68 <= rst_sync_68;
    end

    // Stage 69
    reg rst_sync_69;
    always @(posedge clk or posedge rst_sync_68) begin
        if (rst_sync_68)
            rst_sync_69 <= 1'b1;
        else
            rst_sync_69 <= rst_sync_69;
    end

    // Stage 70
    reg rst_sync_70;
    always @(posedge clk or posedge rst_sync_69) begin
        if (rst_sync_69)
            rst_sync_70 <= 1'b1;
        else
            rst_sync_70 <= rst_sync_70;
    end

    // Stage 71
    reg rst_sync_71;
    always @(posedge clk or posedge rst_sync_70) begin
        if (rst_sync_70)
            rst_sync_71 <= 1'b1;
        else
            rst_sync_71 <= rst_sync_71;
    end

    // Stage 72
    reg rst_sync_72;
    always @(posedge clk or posedge rst_sync_71) begin
        if (rst_sync_71)
            rst_sync_72 <= 1'b1;
        else
            rst_sync_72 <= rst_sync_72;
    end

    // Stage 73
    reg rst_sync_73;
    always @(posedge clk or posedge rst_sync_72) begin
        if (rst_sync_72)
            rst_sync_73 <= 1'b1;
        else
            rst_sync_73 <= rst_sync_73;
    end

    // Stage 74
    reg rst_sync_74;
    always @(posedge clk or posedge rst_sync_73) begin
        if (rst_sync_73)
            rst_sync_74 <= 1'b1;
        else
            rst_sync_74 <= rst_sync_74;
    end

    // Stage 75
    reg rst_sync_75;
    always @(posedge clk or posedge rst_sync_74) begin
        if (rst_sync_74)
            rst_sync_75 <= 1'b1;
        else
            rst_sync_75 <= rst_sync_75;
    end

    // Stage 76
    reg rst_sync_76;
    always @(posedge clk or posedge rst_sync_75) begin
        if (rst_sync_75)
            rst_sync_76 <= 1'b1;
        else
            rst_sync_76 <= rst_sync_76;
    end

    // Stage 77
    reg rst_sync_77;
    always @(posedge clk or posedge rst_sync_76) begin
        if (rst_sync_76)
            rst_sync_77 <= 1'b1;
        else
            rst_sync_77 <= rst_sync_77;
    end

    // Stage 78
    reg rst_sync_78;
    always @(posedge clk or posedge rst_sync_77) begin
        if (rst_sync_77)
            rst_sync_78 <= 1'b1;
        else
            rst_sync_78 <= rst_sync_78;
    end

    // Stage 79
    reg rst_sync_79;
    always @(posedge clk or posedge rst_sync_78) begin
        if (rst_sync_78)
            rst_sync_79 <= 1'b1;
        else
            rst_sync_79 <= rst_sync_79;
    end

    // Stage 80
    reg rst_sync_80;
    always @(posedge clk or posedge rst_sync_79) begin
        if (rst_sync_79)
            rst_sync_80 <= 1'b1;
        else
            rst_sync_80 <= rst_sync_80;
    end

    // Stage 81
    reg rst_sync_81;
    always @(posedge clk or posedge rst_sync_80) begin
        if (rst_sync_80)
            rst_sync_81 <= 1'b1;
        else
            rst_sync_81 <= rst_sync_81;
    end

    // Stage 82
    reg rst_sync_82;
    always @(posedge clk or posedge rst_sync_81) begin
        if (rst_sync_81)
            rst_sync_82 <= 1'b1;
        else
            rst_sync_82 <= rst_sync_82;
    end

    // Stage 83
    reg rst_sync_83;
    always @(posedge clk or posedge rst_sync_82) begin
        if (rst_sync_82)
            rst_sync_83 <= 1'b1;
        else
            rst_sync_83 <= rst_sync_83;
    end

    // Stage 84
    reg rst_sync_84;
    always @(posedge clk or posedge rst_sync_83) begin
        if (rst_sync_83)
            rst_sync_84 <= 1'b1;
        else
            rst_sync_84 <= rst_sync_84;
    end

    // Stage 85
    reg rst_sync_85;
    always @(posedge clk or posedge rst_sync_84) begin
        if (rst_sync_84)
            rst_sync_85 <= 1'b1;
        else
            rst_sync_85 <= rst_sync_85;
    end

    // Stage 86
    reg rst_sync_86;
    always @(posedge clk or posedge rst_sync_85) begin
        if (rst_sync_85)
            rst_sync_86 <= 1'b1;
        else
            rst_sync_86 <= rst_sync_86;
    end

    // Stage 87
    reg rst_sync_87;
    always @(posedge clk or posedge rst_sync_86) begin
        if (rst_sync_86)
            rst_sync_87 <= 1'b1;
        else
            rst_sync_87 <= rst_sync_87;
    end

    // Stage 88
    reg rst_sync_88;
    always @(posedge clk or posedge rst_sync_87) begin
        if (rst_sync_87)
            rst_sync_88 <= 1'b1;
        else
            rst_sync_88 <= rst_sync_88;
    end

    // Stage 89
    reg rst_sync_89;
    always @(posedge clk or posedge rst_sync_88) begin
        if (rst_sync_88)
            rst_sync_89 <= 1'b1;
        else
            rst_sync_89 <= rst_sync_89;
    end

    // Stage 90
    reg rst_sync_90;
    always @(posedge clk or posedge rst_sync_89) begin
        if (rst_sync_89)
            rst_sync_90 <= 1'b1;
        else
            rst_sync_90 <= rst_sync_90;
    end

    // Stage 91
    reg rst_sync_91;
    always @(posedge clk or posedge rst_sync_90) begin
        if (rst_sync_90)
            rst_sync_91 <= 1'b1;
        else
            rst_sync_91 <= rst_sync_91;
    end

    // Stage 92
    reg rst_sync_92;
    always @(posedge clk or posedge rst_sync_91) begin
        if (rst_sync_91)
            rst_sync_92 <= 1'b1;
        else
            rst_sync_92 <= rst_sync_92;
    end

    // Stage 93
    reg rst_sync_93;
    always @(posedge clk or posedge rst_sync_92) begin
        if (rst_sync_92)
            rst_sync_93 <= 1'b1;
        else
            rst_sync_93 <= rst_sync_93;
    end

    // Stage 94
    reg rst_sync_94;
    always @(posedge clk or posedge rst_sync_93) begin
        if (rst_sync_93)
            rst_sync_94 <= 1'b1;
        else
            rst_sync_94 <= rst_sync_94;
    end

    // Stage 95
    reg rst_sync_95;
    always @(posedge clk or posedge rst_sync_94) begin
        if (rst_sync_94)
            rst_sync_95 <= 1'b1;
        else
            rst_sync_95 <= rst_sync_95;
    end

    // Stage 96
    reg rst_sync_96;
    always @(posedge clk or posedge rst_sync_95) begin
        if (rst_sync_95)
            rst_sync_96 <= 1'b1;
        else
            rst_sync_96 <= rst_sync_96;
    end

    // Stage 97
    reg rst_sync_97;
    always @(posedge clk or posedge rst_sync_96) begin
        if (rst_sync_96)
            rst_sync_97 <= 1'b1;
        else
            rst_sync_97 <= rst_sync_97;
    end

    // Stage 98
    reg rst_sync_98;
    always @(posedge clk or posedge rst_sync_97) begin
        if (rst_sync_97)
            rst_sync_98 <= 1'b1;
        else
            rst_sync_98 <= rst_sync_98;
    end

    // Stage 99
    reg rst_sync_99;
    always @(posedge clk or posedge rst_sync_98) begin
        if (rst_sync_98)
            rst_sync_99 <= 1'b1;
        else
            rst_sync_99 <= rst_sync_99;
    end

    // Stage 100
    reg rst_sync_100;
    always @(posedge clk or posedge rst_sync_99) begin
        if (rst_sync_99)
            rst_sync_100 <= 1'b1;
        else
            rst_sync_100 <= rst_sync_100;
    end

    // Generate the output based on the last stage and polarity
    // If RST_POL is 1 (active high), output is the last stage directly.
    // If RST_POL is 0 (active low), output is the inverse of the last stage.
    assign sync_rst_o = RST_POL ? rst_sync_100 : ~rst_sync_100;

endmodule
```<|im_end|>
