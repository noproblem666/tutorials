/* Copyright 2013-present Barefoot Networks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

header_type ls_metadata_t {
	fields {
		link_state: 1; 
	}
}

metadata ls_metadata_t ls_metadata;

register link_state {
	width: 1;
	instance_count: 10;
}

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action _drop() {
    drop();
}

action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
	register_read(ls_metadata.link_state, link_state, port);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
		_drop;
		forward;
    }
    size : 512;
}
table drop_packets {
	actions { 
		_drop;
	}
}

control ingress{
    apply(dmac);
	if (ls_metadata.link_state == 0) {
		apply(drop_packets);
	}
}
