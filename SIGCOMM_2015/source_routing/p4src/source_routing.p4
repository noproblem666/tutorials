/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

header_type ingress_metadata_t{
	fields{
		link_metadata: 32; //probably we can use just one bit here and not 32!
	}
}

metadata ingress_metadata_t ingress_metadata;

header_type failover_metadata_t{
	fields{
		starting_port: 5;
		all_ports_status: 3;
	}
}

metadata failover_metadata_t failover_metadata;

register link_state{
	width: 32;
	instance_count: 10;
}


parser start {
    return ingress;
}

action _drop() {
    no_op();
}

action route(port_to_send) {
	modify_field(standard_metadata.egress_spec, port_to_send);
	register_read(ingress_metadata.link_metadata, link_state, 3);
}

table route_pkt{
	reads{
		standard_metadata.ingress_port: exact;
	}
	actions{
		_drop;
		route;
	}
	size: 3;
}
header_type my_metadata_t{
	fields{
		link_state: 1;
	}
}
metadata my_metadata_t m;

/* Copy the linke state from the table into the metadata */
action set_link_state(link_state){
	modify_field(m.link_state, link_state);
}
/* An entry for each egress prot contains its link state */
table egress_port_link_state{
	reads{
		//standard_metadata.egress_spec: ternary; 		// ternary type alles to use masks! 
		standard_metadata.egress_spec: exact;
	}
	actions{
		set_link_state;
	}
	size: 11;
}

table drop_packets{
	actions{
		_drop;
	}
}

control ingress {
	apply(route_pkt);
	apply(egress_port_link_state);
	if(m.link_state == 0){
		apply(drop_packets);
	}
}

control egress {
    // leave empty
}
