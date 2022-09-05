// Route that receives deviceId as an argument
import 'package:flutter/material.dart';
import 'package:flutter_esp/flutter_esp.dart';
import 'package:flutter_esp/flutter_esp_platform_interface.dart';

class NetworkSelectionPage extends StatefulWidget {
  const NetworkSelectionPage({Key? key}) : super(key: key);

  // Page url
  static const String url = '/networks';

  // Navigate to Network Selection page
  static void go(BuildContext context, NetworkSelectionPageArgs args) {
    Navigator.of(context).pushNamed(url, arguments: args);
  }

  @override
  State<NetworkSelectionPage> createState() => _NetworkSelectionPageState();
}

class _NetworkSelectionPageState extends State<NetworkSelectionPage> {
  final FlutterEsp _flutterEspPlugin = FlutterEsp();
  _NetworksState state = _NetworksState.loading();

  @override
  void initState() {
    super.initState();
    // Set connect method to run after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connect();
    });
  }

  _connect() async {
    // Extract route arguments
    final args =
        ModalRoute.of(context)!.settings.arguments as NetworkSelectionPageArgs;
    final id = args.deviceId;
    final pop = args.proofOfPossession;

    setState(() {
      state = _NetworksState.loading();
    });

    String? error;
    List<GetNetworksResult>? networks;

    try {
      networks = await _flutterEspPlugin.getAvailableNetworks(
        GetNetworksArguments(
          deviceId: id,
          proofOfPossession: pop,
        ),
      );
    } catch (e) {
      error = 'Failed to get networks: $e';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      state = _NetworksState(
        loading: false,
        error: error,
        networks: networks,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Network"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _connect,
          ),
        ],
      ),
      body: SafeArea(
        child: _NetworkList(
            state: state, onSelect: (network) => print(network.ssid)),
      ),
    );
  }
}

// Page arguments
class NetworkSelectionPageArgs {
  final String deviceId;
  final String? proofOfPossession;

  NetworkSelectionPageArgs({
    required this.deviceId,
    this.proofOfPossession,
  });
}

class _NetworksState {
  final bool loading;
  final String? error;
  final List<GetNetworksResult>? networks;

  _NetworksState({
    this.loading = false,
    this.error,
    this.networks,
  });

  factory _NetworksState.loading() => _NetworksState(loading: true);
}

class _NetworkList extends StatelessWidget {
  final _NetworksState state;
  final void Function(GetNetworksResult) onSelect;

  const _NetworkList({
    Key? key,
    required this.state,
    required this.onSelect,
  }) : super(key: key);

  Widget getIconForRssi(int rssi) {
    if (rssi > -60) {
      return const Icon(Icons.signal_wifi_4_bar);
    } else if (rssi > -70) {
      return const Icon(Icons.network_wifi_3_bar);
    } else if (rssi > -80) {
      return const Icon(Icons.network_wifi_2_bar);
    } else if (rssi > -90) {
      return const Icon(Icons.network_wifi_1_bar);
    } else {
      return const Icon(Icons.network_wifi_1_bar);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!),
      );
    }

    if (state.networks == null || state.networks!.isEmpty) {
      return const Center(
        child: Text("No networks found"),
      );
    }

    return ListView.builder(
      itemCount: state.networks!.length,
      itemBuilder: (context, index) {
        final network = state.networks![index];
        return ListTile(
          title: Text(network.ssid),
          subtitle: Text(network.getMacAddress().toUpperCase()),
          trailing: getIconForRssi(network.rssi),
          onTap: () => onSelect(network),
        );
      },
    );
  }
}
