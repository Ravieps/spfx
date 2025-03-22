<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<script type="text/javascript">
    function TriggerWorkflowForSelectedItems() {
        var selectedItems = SP.ListOperation.Selection.getSelectedItems();
        if (selectedItems.length === 0) {
            alert("Please select at least one item.");
            return;
        }

        var siteUrl = _spPageContextInfo.webAbsoluteUrl;
        var listId = _spPageContextInfo.pageListId.replace(/[{}]/g, ""); // Get List ID dynamically
        var workflowSubscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"; // Change to your workflow GUID

        for (var i = 0; i < selectedItems.length; i++) {
            var itemId = selectedItems[i].id;
            StartWorkflow2013(itemId, workflowSubscriptionId, siteUrl, listId);
        }
    }

    function StartWorkflow2013(itemId, workflowSubscriptionId, siteUrl, listId) {
        var requestUrl = siteUrl + "/_api/SP.WorkflowServices.WorkflowInstanceService.StartWorkflowOnListItem";

        var requestBody = JSON.stringify({
            "itemId": itemId,
            "listId": listId,
            "workflowSubscriptionId": workflowSubscriptionId
        });

        $.ajax({
            url: requestUrl,
            type: "POST",
            data: requestBody,
            headers: {
                "Accept": "application/json;odata=verbose",
                "Content-Type": "application/json;odata=verbose",
                "X-RequestDigest": $("#__REQUESTDIGEST").val()
            },
            success: function (data) {
                console.log("Workflow started for item ID: " + itemId);
            },
            error: function (error) {
                console.log("Error starting workflow: ", error);
            }
        });
    }
</script>
