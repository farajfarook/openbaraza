
    <div class="modal fade" id="basic" tabindex="-1" role="basic" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true"></button>
                    <h4 class="modal-title"><i class="fa fa-unlock-alt" style="color:#3598dc; font-size:24px"></i> Change Password</h4>
                </div>
                <form class="form-horizontal" action="#">
                <div class="modal-body">
                    <div id="pass_alert_div"></div>
                       <!-- <div class="form-group">
                            <label class="control-label">Current Password</label>
                            <input type="password" class="form-control" id="txtOldPassword" required/>
                        </div>
                        <div class="form-group">
                            <label class="control-label">New Password</label>
                            <input type="password" class="form-control" id="txtNewPassword" required/>
                        </div>
                        <div class="form-group">
                            <label class="control-label">Re-type New Password</label>
                            <input type="password" class="form-control"   id="txtConfirmNew" required/>
                        </div>-->
                    
                    <div class="form-group">
                        <label class=" col-md-3 control-label" for="txtOldPassword">Current Password</label>
                        <div class="col-md-7">
                            <input type="password" class="form-control" id="txtOldPassword" name="txtOldPassword" required/>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class=" col-md-3 control-label" for="txtNewPassword">New Password</label>
                        <div class="col-md-7">
                            <input type="password" class="form-control" id="txtNewPassword" name="txtNewPassword" required/>
                        </div>
                    </div>
                    
                    
                    <div class="form-group">
                        <label class=" col-md-3 control-label" for="txtConfirmNew">Confirm Password</label>
                        <div class="col-md-7">
                            <input type="password" class="form-control" id="txtConfirmNew" name="txtConfirmNew" required/>
                        </div>
                    </div>
                    
                    
                    
                    
                        
                    </form>

                    
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn default" data-dismiss="modal">Close</button>
                    <button type="button" class="btn green-haze" id="btnChangePass">Change Password</button>
                </div>
                </form>
            </div>
            <!-- /.modal-content -->
        </div>
        <!-- /.modal-dialog -->
    </div>


<script type="text/javascript">
$('#btnChangePass').click(function(){
    var oldpass = $.trim($('#txtOldPassword').val());
    var newpass = $.trim($('#txtNewPassword').val());
    var confirm = $.trim($('#txtConfirmNew').val());
    var ok = true;
    
    if(oldpass === '' || oldpass == null){
        runAlert('Enter Current password', 'danger', 'warning'); ok = false;  $('#txtOldPassword').focus(); return false;
    }
    
    if(newpass === '' || newpass == null){
        runAlert('Enter New password', 'danger', 'warning'); ok = false; $('#txtNewPassword').focus(); return false;
    }
    
    if(newpass.length < 5){
        runAlert('New Password is too short (Min 5)', 'danger', 'warning'); ok = false; $('#txtNewPassword').focus(); return false;
    }
    
    if(newpass != confirm){
        runAlert('Your New Passwords Don\'t Match', 'danger', 'warning'); ok = false; $('#txtConfirmNew').focus(); return false;
    }
    
    if(ok){
        runAlert('Please Wait', 'info', 'info');
        $.post('ajax', {fnct:'password', oldpass:oldpass, newpass:newpass}, function(data){
            if(data.success == 1){
                runAlert(data.message, 'success', 'info');
            }else if(data.success == 0){
                runAlert(data.message, 'danger', 'warning');   
            }
            $('#txtOldPassword,#txtNewPassword, #txtConfirmNew').val('');
        },'JSON');
    }else{
        runAlert('Your Request Could not be completed', 'danger', 'warning'); ok = false; $('#txtConfirmNew').focus(); return false;
        
    }
});
    

function runAlert(msg, type, icon){
    Metronic.alert({
                container: '#pass_alert_div', // alerts parent container(by default placed after the page breadcrumbs)
                place: 'append', // append or prepent in container 
                type: type,  // alert's type
                message: msg,  // alert's message
                close: true, // make alert closable
                reset: true, // close all previouse alerts first
                focus: false, // auto scroll to the alert after shown
                closeInSeconds: 0, // auto close after defined seconds
                icon: icon // put icon before the message
            });
}

</script>


