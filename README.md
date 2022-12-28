# InternDevOpsEngineer

According to tasks requirement we do not have to choose Archive access tier, because it perfect for long term storage, but it is not appropriate for r\w access for regular basis.
Also, we have to decide what kind of redundancy we need to use. In most cases it is enough LRS - local datacenter replication, but it is dangerous choice for vary kind disaster situation.
ZRS - reliable enough for certain situation, it provides inter zone replication which good for many disaster circumstances with reasonable costs.
GRS and it variance - the most expensive and almost unbreakable replication between data center in different availability zones.
Also, task does not provide information about io profile, that lead as to difficult choice between hot and cold storage. While cold storage cheap as data storage porpouse whith low IO, he may overcome its comarable low cost if IO encreased a lot.

## final decision
I have choose ZRS and cold storage, because it is enough in general while tasks description have not enough clearance about.

## Final word

After apply Terraform configuration we will get VM and network file share, which available to mount inside the VM by the PS script, provided by Azure. But by the fast search I have not find a way, hot to automate attaching this drive inside VM by Terraform. Some topics in Internet suggested to provide custom startup script to achieve automount.
Also it is impossible to name storage account as CorpStorage01, because name must be unique across the entire Azure service and also name must consist from low case letters and numbers.
