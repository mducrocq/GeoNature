import { Component, OnInit } from "@angular/core";
import { animate, state, style, transition, trigger } from '@angular/animations';
import { MatDialogRef } from '@angular/material';
import { FormBuilder, FormGroup, Validators } from "@angular/forms";
import { combineLatest } from "rxjs";
import { filter, map } from "rxjs/operators";
import { ModuleConfig } from "../../module.config";  
import { OcctaxFormMapService } from '../map/map.service';
import { OcctaxFormReleveService } from '../releve/releve.service';
import { OcctaxFormOccurrenceService } from '../occurrence/occurrence.service';
import { OcctaxFormParamService } from './form-param.service';


@Component({
  selector: "pnx-occtax-form-param",
  templateUrl: "./form-param.dialog.html",
  styleUrls: ["./form-param.dialog.scss"],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({height: '0px', minHeight: '0', margin: '-1px', overflow: 'hidden', padding: '0'})),
      state('expanded', style({height: '*'})),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class OcctaxFormParamDialog implements OnInit {

  public occtaxConfig: any;
  public paramsForm: FormGroup;
  public selectedIndex: number = null;
  public state: string = 'collapsed';

  get geometryParamForm() { return this.paramsForm.get('geometry'); }
  get releveParamForm() { return this.paramsForm.get('releve'); }
  get occurrenceParamForm() { return this.paramsForm.get('occurrence'); }
  get countingParamForm() { return this.paramsForm.get('counting'); }

  constructor(
    public dialogRef: MatDialogRef<OcctaxFormParamDialog>,
    private fb: FormBuilder,
    private occtaxFormMapService: OcctaxFormMapService,
    private occtaxFormReleveService: OcctaxFormReleveService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public occtaxFormParamService: OcctaxFormParamService
  ) {
    this.occtaxConfig = ModuleConfig;
  }
  
  ngOnInit() {

    this.paramsForm = this.fb.group({
      geometry:null,
      releve: this.fb.group({
        id_dataset: null,
        date_min: null,
        date_max: null,
        hour_min: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
        hour_max: [null, Validators.pattern("^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$")],
        comment: null,
        id_nomenclature_obs_technique: null,
        observers: null,
        observers_txt: null,
        id_nomenclature_grp_typ: null
      }),
      occurrence: this.fb.group({
        id_nomenclature_obs_meth: null,
        id_nomenclature_bio_condition: null,
        id_nomenclature_bio_status: null,
        id_nomenclature_naturalness: null,
        id_nomenclature_exist_proof: null,
        id_nomenclature_observation_status: null,
        id_nomenclature_diffusion_level: null,
        id_nomenclature_blurring: null,
        id_nomenclature_source_status: null,
        determiner: null,
        id_nomenclature_determination_method: null,
        sample_number_proof: null,
        comment: null
      }),
      counting: this.fb.group({
        id_nomenclature_life_stage: null,
        id_nomenclature_sex: null,
        id_nomenclature_obj_count: null,
        id_nomenclature_type_count: null,
        count_min: null,
        count_max: null
      })
    });
    
    this.paramsForm.patchValue(this.occtaxFormParamService.parameters);

    //a chaque changement du formulairen on patch le service des paramètres
    this.paramsForm.valueChanges
                .pipe(
                  filter(()=>this.paramsForm.valid)
                )
                .subscribe(values=>this.occtaxFormParamService.parameters = values);

    //Observe l'état des switchs pour activer ou non le formulaire
    this.occtaxFormParamService.releveState
        .subscribe((value: boolean)=>{value ? this.paramsForm.get('releve').enable() : this.paramsForm.get('releve').disable()});
    this.occtaxFormParamService.occurrenceState
        .subscribe((value: boolean)=>{value ? this.paramsForm.get('occurrence').enable() : this.paramsForm.get('occurrence').disable()});
    this.occtaxFormParamService.countingState
        .subscribe((value: boolean)=>{value ? this.paramsForm.get('counting').enable() : this.paramsForm.get('counting').disable()});

    //On observe les cases cochées pour savoir quel onglet affiché
    //Uniquement si un seul switch est activé
    combineLatest(
      this.occtaxFormParamService.geometryState, 
      this.occtaxFormParamService.releveState, 
      this.occtaxFormParamService.occurrenceState, 
      this.occtaxFormParamService.countingState
    )
      .pipe(
        filter(([geometryState, releveState, occurrenceState, countingState])=>{
          //si un unique switch est activé
          return ((geometryState ? 1 : 0) + (releveState ? 1 : 0) + (occurrenceState ? 1 : 0) + (countingState ? 1 : 0)) === 1
        }), 
        map(([geometryState, releveState, occurrenceState, countingState])=>{
          //convertit la case coché en index de tab à activer
          if (geometryState) {
            return 0;
          }
          if (releveState) {
            return 1;
          }
          if (occurrenceState) {
            return 2;
          }
          if (countingState) {
            return 3;
          }
        })
      )
      .subscribe(index=>this.selectedIndex = index)
  }

  geometryFormMapper() {
    console.log("patch")
    this.paramsForm.get('geometry').patchValue(this.occtaxFormMapService.geometry.value);
  }

  releveFormMapper() {
    this.paramsForm.get('releve').patchValue(this.occtaxFormReleveService.propertiesForm.value);
  }

  occurrenceFormMapper() {
    this.paramsForm.get('occurrence').patchValue(this.occtaxFormOccurrenceService.form.value);
  }

  collapse(){
    this.state = (this.state === 'collapsed' ? 'expanded' : 'collapsed');
  }


}