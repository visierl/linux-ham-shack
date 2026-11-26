# ~/.config/quisk/quisk_conf.py
# Station-wide settings not stored in quisk_settings.json
# (GUI radio, audio, and serial PTT/CW settings live in quisk_settings.json)

# Waterfall & Panadapter visual defaults
waterfall_y_scale = 80
waterfall_y_zero = 40
graph_y_scale = 100
graph_y_zero = 0
graph_refresh = 20

# Default waterfall color palette
waterfallPalette = ' Default '

# US Amateur Band Plan frequency markers (ITU Region 2)
# Format: (start_freq_hz, end_freq_hz, color_name)
BandPlan = [
    # 160 Meters
    (1800000, 2000000, 'BandPlan_Phone'),
    # 80 Meters
    (3500000, 3600000, 'BandPlan_CW'),
    (3600000, 4000000, 'BandPlan_Phone'),
    # 60 Meters (Channelized)
    (5330500, 5406500, 'BandPlan_Phone'),
    # 40 Meters
    (7000000, 7125000, 'BandPlan_CW'),
    (7125000, 7300000, 'BandPlan_Phone'),
    # 30 Meters
    (10100000, 10150000, 'BandPlan_CW'),
    # 20 Meters
    (14000000, 14150000, 'BandPlan_CW'),
    (14150000, 14350000, 'BandPlan_Phone'),
    # 17 Meters
    (18068000, 18110000, 'BandPlan_CW'),
    (18110000, 18168000, 'BandPlan_Phone'),
    # 15 Meters
    (21000000, 21200000, 'BandPlan_CW'),
    (21200000, 21450000, 'BandPlan_Phone'),
    # 12 Meters
    (24890000, 24930000, 'BandPlan_CW'),
    (24930000, 24990000, 'BandPlan_Phone'),
    # 10 Meters
    (28000000, 28300000, 'BandPlan_CW'),
    (28300000, 29700000, 'BandPlan_Phone'),
]
