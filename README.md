# InternDevOpsEngineer

According to tasks requirement we do not have to choose Archive access tier, because it perfect for long term storage, but it is not appropriate for r\w access for regular basis.
Also, we have to decide what kind of redundancy we need to use. In most cases it is enough LRS - local datacenter replication, but it is dangerous choice for vary kind disaster situation.
ZRS - reliable enough for certain situation, it provides inter zone replication which good for many disaster circumstances with reasonable costs.
GRS and it variance - the most expensive and almost unbreakable replication between data center in different availability zones.
Also, task does not provide information about io profile, that lead as to difficult choice between hot and cold storage. While cold storage cheap in date storage porpouse whith rarely r\w operations, he may overcome it is comarable low cost if io encreased a lot.

## final decision
I have choose ZRS and cold storage, because it is enough in general while tasks description have not enough clearance about.
